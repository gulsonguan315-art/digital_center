import 'package:flutter/material.dart';
import '../../../modules/resident/settings/setting_page_callback.dart';
import '../../engine/theme/shapes/theme_shapes.dart';
import '../../engine/theme/theme_provider.dart';
import '../../engine/theme/visuals/theme_visuals.dart';
import '../../log/log.dart';
import '../local/local_config_store.dart';
import '../models/system_settings.dart';

/// 📂 系统偏好配置业务专属仓库 (Settings Domain Repository)
/// 负责系统亮暗主题、新拟态圆角视觉样式及日志白名单的冷启动恢复与热加载应用。
class SettingsRepository {
  final LocalConfigStore _localStore;

  SettingsRepository(this._localStore);

  /// 全局唯一单例，在 DataManager 初始化时注入绑定
  static late final SettingsRepository instance;

  /// 启动时冷恢复：自动从专属偏好子仓读取磁盘并分发应用给系统主题引擎和日志系统
  Future<void> restoreSystemSettings() async {
    final settings = await _localStore.settings.readSystemSettings();
    applySettingsToEngine(settings);
  }

  /// 将强类型 SystemSettings 配置项分发应用给内存中的系统引擎
  void applySettingsToEngine(SystemSettings settings) {
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

  /// 业务层向总管家申请：获取当前的系统偏好设置快照
  Future<SystemSettings> getSystemSettings() async {
    return _localStore.settings.readSystemSettings();
  }

  /// 业务层向总管家申请：更新系统配置偏好并立刻写入本地磁盘子仓，同时热应用给引擎
  Future<void> saveSettings(SystemSettings settings) async {
    await _localStore.settings.writeSystemSettings(settings);
    applySettingsToEngine(settings);
  }
}
