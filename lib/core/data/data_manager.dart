import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../modules/resident/settings/setting_page_callback.dart';
import '../engine/theme/shapes/theme_shapes.dart';
import '../engine/theme/theme_provider.dart';
import '../engine/theme/visuals/theme_visuals.dart';
import '../log/log.dart';
import 'local/local_config_store.dart';
import 'models/dashboard_item_config.dart';
import 'models/poetry_data.dart';
import 'models/system_settings.dart';
import 'remote/remote_api_client.dart';

/// 【数据的总管理员】(Centralized Data Manager)
/// 业务层所有的数据请求、更新、修改均向此管理员发起。
/// 大管家自动协调本地持久化（挂载至各自专属业务子仓）与云端 API。
class DataManager {
  DataManager._() {
    _localStore = LocalConfigStore();
    _remoteClient = RemoteApiClient();
    _restoreSystemSettings(); // 🚀 启动时自动恢复用户所有的偏好配置
  }

  /// 全局唯一单例入口，业务层通过 DataManager.instance 统一访问
  static final DataManager instance = DataManager._();

  late final LocalConfigStore _localStore;
  late final RemoteApiClient _remoteClient;

  Stream<List<DashboardItemConfig>>? _dashboardStream;
  Stream<PoetryData>? _poetryStream;
  PoetryData? _lastPoetry; // 内存高保真缓存，支持 Web 重用与零延时同步
  List<DashboardItemConfig>? _lastLayout; // 布局内存高保真缓存，解决广播流二次载入的历史空白问题

  PoetryData get latestPoetry => _lastPoetry ?? PoetryData.defaultPoetry;
  List<DashboardItemConfig> get latestLayout => _lastLayout ?? [];

  /// 暴露异步初始化入口，供 main() 显式阻塞等待偏好配置加载（避免冷启动主题闪烁）
  Future<void> init() async {
    await _restoreSystemSettings();
    try {
      final endpoints = await _localStore.endpoints.readData();
      _remoteClient.apiBaseUrl = endpoints.poetryBaseUrl;
      
      // 🚀 打印当前配置来源提醒 (Print dynamic API endpoints configuration source info)
      final String rawPath = '${_localStore.endpoints.configDirPath}/api_endpoints.json';
      final String formattedPath = Platform.isWindows ? rawPath.replaceAll('/', '\\') : rawPath.replaceAll('\\', '/');
      print('🚀 [System] Loaded API endpoints from: $formattedPath | Poetry Base URL: ${endpoints.poetryBaseUrl}');
      Log.d(LogGroup.network, 'Loaded API endpoints from persistent storage. Path: $formattedPath, Poetry URL: ${endpoints.poetryBaseUrl}');
    } catch (e) {
      print('🚀 [System] Failed to load custom API endpoints. Using default: https://poetry.gulson.cc');
      Log.d(LogGroup.network, 'Failed to load custom API endpoints. Using default: https://poetry.gulson.cc');
    }
    try {
      _lastPoetry = await _localStore.poetry.readPoetry();
    } catch (_) {}
    try {
      _lastLayout = await _localStore.dashboard.readDashboardItems();
    } catch (_) {}
  }

  // ===========================================================================
  // 看板磁贴布局配置 API (Dashboard Layout API)
  // ===========================================================================

  /// 业务层向总管理员申请：响应式持续监听看板布局数据。
  /// 采用“自销毁共享广播流 (Leak-free Recreatable Broadcast Stream)”，完美去重过滤多重订阅性能陷阱。
  Stream<List<DashboardItemConfig>> watchDashboardItems() {
    _dashboardStream ??= _createDashboardStream().asBroadcastStream(
      onCancel: (subscription) {
        // 🛡️ 自销毁：当所有前台微件的订阅全取消（例如切出 Dashboard 页）时，清理共享引用并释放管道
        _dashboardStream = null;
        subscription.cancel();
      },
    );
    return _dashboardStream!;
  }

  /// 创建底层的网格持久化监控管道流
  Stream<List<DashboardItemConfig>> _createDashboardStream() {
    final controller = StreamController<List<DashboardItemConfig>>();

    // 1. Offline-First: 立即向本地磁盘子仓读取并添加缓存数据，实现 0 延时 UI 秒开
    _localStore.dashboard.readDashboardItems().then((cached) {
      _lastLayout = cached; // 🌟 内存高保真缓存
      if (!controller.isClosed) {
        controller.add(cached);
      }
      // 2. Background Sync (SWR): 紧接发起后台异步云端同步，业务层无感
      _syncDashboardItemsInBackground();
    });

    // 3. Reactive Piping: 持续订阅本地网格磁盘子仓 of 响应式广播
    final subscription = _localStore.dashboard.watchDashboardItems().listen(
      (items) {
        _lastLayout = items; // 🌟 内存高保真缓存
        if (!controller.isClosed) {
          controller.add(items);
        }
      },
      onError: (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    controller.onCancel = () {
      subscription.cancel();
    };

    // 🌟 配合 listEquals 进行元素级深比较去重，杜举重复渲染，性能达到最高峰！
    return controller.stream.distinct(listEquals);
  }

  /// 业务层向总管理员申请：将磁贴数据落锁保存进专属排版子仓中
  Future<void> saveDashboardItems(List<DashboardItemConfig> items) async {
    _lastLayout = items; // 🌟 瞬间缓存
    await _localStore.dashboard.writeDashboardItems(items);
  }

  /// 后台异步云端同步逻辑
  Future<void> _syncDashboardItemsInBackground() async {
    try {
      final freshItems = await _remoteClient.fetchDashboardLayout();
      _lastLayout = freshItems; // 🌟 内存高保真缓存
      // 如果云端拉取到了新排版，立刻覆写本地缓存并广播（触发UI响应式热更新）
      await _localStore.dashboard.writeDashboardItems(freshItems);
    } catch (e) {
      // 静默吞下异常，不干扰前台已正常渲染的本地缓存数据
    }
  }

  // ===========================================================================
  // 每日推荐网络古诗词 API (Daily Poetry API)
  // ===========================================================================

  /// 业务层向总管理员申请：响应式收听每日推荐网络诗词。
  /// 同样使用“自销毁共享广播流”，确保高频/并发订阅时 0 重复网络开销、0 内存泄露！
  Stream<PoetryData> watchTodayPoetry() {
    _poetryStream ??= _createPoetryStream().asBroadcastStream(
      onCancel: (subscription) {
        // 🛡️ 自销毁：订阅者全部离开时清空缓存，断开管道防泄漏
        _poetryStream = null;
        subscription.cancel();
      },
    );
    return _poetryStream!;
  }

  /// 创建底层的网络古诗监控管道流
  Stream<PoetryData> _createPoetryStream() {
    final controller = StreamController<PoetryData>();

    // 1. Offline-First: 立即向本地磁盘诗词子仓读取缓存，实现 0 延时闪瞬秒开
    _localStore.poetry.readPoetry().then((cached) {
      _lastPoetry = cached;
      if (!controller.isClosed) {
        controller.add(cached);
      }
      // 2. Background Sync (SWR): 发起后台异步网络请求，对用户无感
      _syncPoetryInBackground();
    });

    // 3. Reactive Piping: 订阅本地磁盘缓存子仓的更改广播
    final subscription = _localStore.poetry.watchPoetry().listen(
      (data) {
        _lastPoetry = data;
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
      onError: (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    controller.onCancel = () {
      subscription.cancel();
    };

    // 🌟 配合重载的 PoetryData.== 操作符进行去重，杜绝网络获取相同数据时的重复刷新！
    return controller.stream.distinct();
  }

  /// 后台异步诗词数据拉取同步逻辑
  Future<void> _syncPoetryInBackground() async {
    try {
      final fresh = await _remoteClient.fetchTodayPoetry();
      // 拉取成功后直接刷写本地磁盘缓存，自动广播触发前台 UI 刷新
      await _localStore.poetry.writePoetry(fresh);
    } catch (e) {
      // 容错：网络离线或接口异常时，静默捕获异常，前台完美展示上一次缓存的古诗
    }
  }

  /// 业务层向总管理员申请：保存并回写诗词标记数据（离线秒写 + 异步网络回传 SWR）
  Future<void> savePoetryMarks(PoetryData updatedPoetry) async {
    _lastPoetry = updatedPoetry;
    // 1. 立刻写入本地缓存子仓，以触发前台 UI 看板同步响应式更新
    await _localStore.poetry.writePoetry(updatedPoetry);

    // 2. 后台异步发送网络回传保存，完全对前台无阻碍，支持断网离线操作
    _uploadPoetryMarksInBackground(updatedPoetry.id, updatedPoetry.markedLines);
  }

  Future<void> _uploadPoetryMarksInBackground(
    String poemId,
    List<int> markedLines,
  ) async {
    try {
      await _remoteClient.uploadPoemMark(poemId, markedLines);
    } catch (e) {
      // 容错：静默吸收网络异常，保障极端的离线手账体验
    }
  }

  // ===========================================================================
  // 系统设置偏好配置 API (System Settings API)
  // ===========================================================================

  /// 启动时冷恢复：自动从专属偏好子仓读取磁盘并分发应用给系统主题引擎和日志系统
  Future<void> _restoreSystemSettings() async {
    final settings = await _localStore.settings.readSystemSettings();
    _applySettingsToEngine(settings);
  }

  /// 将强类型 SystemSettings 配置项分发应用给内存中的系统引擎
  void _applySettingsToEngine(SystemSettings settings) {
    try {
      // 1. 恢复亮/暗色彩模式
      final mode = settings.themeMode == 'light'
          ? ThemeMode.light
          : settings.themeMode == 'night'
          ? ThemeMode.dark
          : ThemeMode.system;
      ThemeProvider.instance.setThemeMode(mode);

      // 2. 恢复视觉风格 (扁平/玻璃/新拟态)
      final visual = VisualStyle.values.firstWhere(
        (e) => e.name == settings.visualStyle,
        orElse: () => VisualStyle.neumorphic,
      );
      ThemeProvider.instance.setVisualStyle(visual);

      // 3. 恢复直角/圆角形状风格
      final shape = ShapeStyle.values.firstWhere(
        (e) => e.name == settings.shapeStyle,
        orElse: () => ShapeStyle.soft,
      );
      ThemeProvider.instance.setShapeStyle(shape);

      // 4. 恢复自定义设置 ValueNotifier 的值
      SettingPageCallback.customModeNotifier.value = settings.customMode;

      // 5. 恢复日志过滤白名单列表
      Log.enabledGroupsNotifier.value = Set<String>.from(
        settings.enabledLogGroups,
      );
    } catch (e) {
      // 容错防御：防止在应用早期启动时，部分静态引擎未初始化完毕
    }
  }

  /// 业务层向总管理员申请：获取当前的系统偏好设置快照
  Future<SystemSettings> getSystemSettings() async {
    return _localStore.settings.readSystemSettings();
  }

  /// 业务层向总管理员申请：更新系统配置偏好并立刻写入本地磁盘子仓，同时热应用给引擎
  Future<void> saveSettings(SystemSettings settings) async {
    await _localStore.settings.writeSystemSettings(settings);
    _applySettingsToEngine(settings);
  }
}
