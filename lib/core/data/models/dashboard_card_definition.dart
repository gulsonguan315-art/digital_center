import 'dashboard_item_config.dart';

/// 📂 看板卡片数据定义 (Dashboard Card Data Definition)
/// 纯数据层定义，不依赖 flutter/material.dart，不包含 UI 组件和图标。
class DashboardCardDefinition {
  final String id;
  final DashboardItemConfig defaultConfig;
  final bool showInManager;

  const DashboardCardDefinition({
    required this.id,
    required this.defaultConfig,
    this.showInManager = true,
  });
}

/// 📁 看板注册表数据 (Dashboard Core Registry)
class DashboardRegistry {
  const DashboardRegistry._();

  // --- Active Card Constant IDs ---
  static const String clockCardId = 'dash_clock';
  static const String poetryCardId = 'dash_poetry';
  static const String systemMonitorCardId = 'dash_system_monitor';
  static const String widgetManagerCardId = 'dash_widget_manager';
  static const String weatherCardId = 'dash_weather';

  static final List<DashboardCardDefinition> definitions = [
    const DashboardCardDefinition(
      id: clockCardId,
      defaultConfig: DashboardItemConfig(
        id: clockCardId,
        x: 0,
        y: 0,
        spanX: 4,
        spanY: 1,
      ),
    ),
    const DashboardCardDefinition(
      id: poetryCardId,
      defaultConfig: DashboardItemConfig(
        id: poetryCardId,
        x: 0,
        y: 1,
        spanX: 3,
        spanY: 2,
      ),
    ),
    const DashboardCardDefinition(
      id: systemMonitorCardId,
      defaultConfig: DashboardItemConfig(
        id: systemMonitorCardId,
        x: 0,
        y: 2,
        spanX: 4,
        spanY: 1,
      ),
    ),
    const DashboardCardDefinition(
      id: widgetManagerCardId,
      defaultConfig: DashboardItemConfig(
        id: widgetManagerCardId,
        x: 0,
        y: 3,
        spanX: 4,
        spanY: 1,
      ),
      showInManager: false,
    ),
    const DashboardCardDefinition(
      id: weatherCardId,
      defaultConfig: DashboardItemConfig(
        id: weatherCardId,
        x: 0,
        y: 4,
        spanX: 4,
        spanY: 2,
      ),
    ),
  ];

  static List<String> get activeCardIds =>
      definitions.map((c) => c.id).toList();
  static List<DashboardItemConfig> get defaultItems =>
      definitions.map((c) => c.defaultConfig).toList();
}
