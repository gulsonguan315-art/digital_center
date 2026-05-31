import 'dart:async';
import 'package:flutter/foundation.dart';
import '../local/local_config_store.dart';
import '../models/dashboard_item_config.dart';
import '../remote/remote_api_client.dart';

/// 📂 看板磁贴布局业务专属仓库 (Dashboard Layout Domain Repository)
/// 负责卡片位置、大小（X/Y 坐标，Span 跨度）的 SWR 持久化监控与防抖写入。
class DashboardRepository {
  final LocalConfigStore _localStore;
  final RemoteApiClient _remoteClient;

  DashboardRepository(this._localStore, this._remoteClient);

  /// 全局唯一单例，在 DataManager 初始化时注入绑定
  static late final DashboardRepository instance;

  Stream<List<DashboardItemConfig>>? _dashboardStream;
  List<DashboardItemConfig>? _lastLayout; // 布局内存高保真缓存，解决广播流二次载入的历史空白问题

  List<DashboardItemConfig> get latestLayout => _lastLayout ?? [];

  /// 用于引导启动加载内存缓存
  Future<void> init() async {
    try {
      _lastLayout = await _localStore.dashboard.readDashboardItems();
    } catch (_) {}
  }

  /// 业务层向总管家申请：响应式持续监听看板布局数据。
  /// 采用“自销毁共享广播流”，完美去重过滤多重订阅性能陷阱。
  Stream<List<DashboardItemConfig>> watchDashboardItems() {
    _dashboardStream ??= _createDashboardStream().asBroadcastStream(
      onCancel: (subscription) {
        // 🛡️ 自销毁：当所有订阅全取消（例如切出 Dashboard 页）时，清理共享引用并释放管道
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

    // 🌟 配合 listEquals 进行元素级深比较去重，性能达到最高峰！
    return controller.stream.distinct(listEquals);
  }

  /// 业务层向总管家申请：将磁贴数据落锁保存进专属排版子仓中
  Future<void> saveDashboardItems(List<DashboardItemConfig> items) async {
    _lastLayout = items; // 🌟 瞬间缓存
    await _localStore.dashboard.writeDashboardItemsDebounced(items);
  }

  /// 业务层向总管家申请：仅更新排版坐标和大小（x, y, spanX, spanY），
  /// 保持当前最新实时的启用状态（enabled）不被覆盖。
  Future<void> saveDashboardLayout(
    List<DashboardItemConfig> layoutItems,
  ) async {
    final currentItems = List<DashboardItemConfig>.from(latestLayout);
    for (final layoutItem in layoutItems) {
      final idx = currentItems.indexWhere((e) => e.id == layoutItem.id);
      if (idx != -1) {
        currentItems[idx] = currentItems[idx].copyWith(
          x: layoutItem.x,
          y: layoutItem.y,
          spanX: layoutItem.spanX,
          spanY: layoutItem.spanY,
        );
      }
    }
    _lastLayout = currentItems; // 🌟 瞬间缓存
    await _localStore.dashboard.writeDashboardItemsDebounced(currentItems);
  }

  /// 后台异步云端同步逻辑
  Future<void> _syncDashboardItemsInBackground() async {
    try {
      final freshItems = await _remoteClient.fetchDashboardLayout();
      _lastLayout = freshItems; // 🌟 内存高保真缓存
      // 如果云端拉取到了新排版，立刻覆写本地缓存并广播（触发UI响应式热更新）
      await _localStore.dashboard.writeDashboardItemsDebounced(freshItems);
    } catch (e) {
      // 静默吞下异常，不干扰前台已正常渲染的本地缓存数据
    }
  }
}
