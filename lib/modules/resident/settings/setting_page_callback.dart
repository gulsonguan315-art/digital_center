import 'package:flutter/material.dart';

import '../../../core/data/data_manager.dart';
import '../../../core/data/models/system_settings.dart';
import '../../../core/engine/theme/shapes/theme_shapes.dart';
import '../../../core/engine/theme/theme_provider.dart';
import '../../../core/engine/theme/visuals/theme_visuals.dart';
import '../../../core/log/log_api.dart';
import '../../../core/engine/audio/app_audio_service.dart';

/// 设置页面的交互回调逻辑 - 业务层 (Data Source & Action)
class SettingPageCallback {
  /// 统一将最新的偏好状态同步写入本地大管家数据库中
  static void _syncSettingsToDataManager() {
    final settings = SystemSettings(
      themeMode: getCurrentThemeKey(),
      visualStyle: getCurrentVisualKey(),
      shapeStyle: getCurrentShapeKey(),
      customMode: getCurrentCustomKey(),
      enabledLogGroups: logGroupsNotifier.value.toList(),
      systemVolume: AppAudioService.instance.volume,
    );
    DataManager.instance.saveSettings(settings);
  }

  /// 获取当前 UI 需要显示的主题 Key
  static String getCurrentThemeKey() {
    final mode = ThemeProvider.instance.themeMode;
    if (mode == ThemeMode.light) return 'light';
    if (mode == ThemeMode.dark) return 'night';
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.light ? 'light' : 'night';
  }

  /// 获取当前视觉风格 Key
  static String getCurrentVisualKey() {
    return ThemeProvider.instance.visualStyle.name;
  }

  /// 获取当前形状风格 Key
  static String getCurrentShapeKey() {
    return ThemeProvider.instance.shapeStyle.name;
  }

  /// 注册主题监听
  static void addThemeListener(VoidCallback listener) {
    ThemeProvider.instance.addListener(listener);
  }

  /// 移除主题监听
  static void removeThemeListener(VoidCallback listener) {
    ThemeProvider.instance.removeListener(listener);
  }

  /// 处理主题模式切换 (Color Mode)
  static void onThemeModeChanged(String themeKey) {
    final themeMode = themeKey == 'light' ? ThemeMode.light : ThemeMode.dark;
    ThemeProvider.instance.setThemeMode(themeMode);
    _syncSettingsToDataManager(); // 👈 每次修改自动落锁写入管家磁盘
  }

  /// 处理视觉风格切换 (Visual Mode)
  static void onVisualModeChanged(String visualKey) {
    final style = VisualStyle.values.firstWhere((e) => e.name == visualKey);
    ThemeProvider.instance.setVisualStyle(style);
    _syncSettingsToDataManager(); // 👈 每次修改自动落锁写入管家磁盘
  }

  /// 处理形状风格切换 (Shape Mode)
  static void onShapeModeChanged(String shapeKey) {
    final style = ShapeStyle.values.firstWhere((e) => e.name == shapeKey);
    ThemeProvider.instance.setShapeStyle(style);
    _syncSettingsToDataManager(); // 👈 每次修改自动落锁写入管家磁盘
  }

  // --- Mock Custom Settings ---

  static final customModeNotifier = ValueNotifier<String>('a');

  static String getCurrentCustomKey() => customModeNotifier.value;

  static void onCustomModeChanged(String key) {
    customModeNotifier.value = key;
    _syncSettingsToDataManager(); // 👈 每次修改自动落锁写入管家磁盘
  }

  // --- 日志分组动作 ---

  static ValueNotifier<Set<String>> get logGroupsNotifier => Log.enabledGroupsNotifier;

  static void onLogGroupToggled(String group) {
    Log.toggle(group);
    _syncSettingsToDataManager(); // 👈 每次修改自动落锁写入管家磁盘
  }
}
