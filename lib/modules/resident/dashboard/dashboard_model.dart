import 'package:flutter/material.dart';
import '../../../core/data/models/dashboard_item_config.dart';
import '../../widgets/clock/clock_view.dart';
import '../../widgets/poetry/poetry_view.dart';
import '../../widgets/system_monitor/system_monitor_view.dart';
import '../../widgets/widget_manager/widget_manager_view.dart';

/// 📂 看板卡片元数据 (Dashboard Card Metadata)
class DashboardCardMeta {
  final String id;
  final String title;
  final IconData icon;
  final DashboardItemConfig defaultConfig;
  final Widget widget;
  final bool showInManager;

  const DashboardCardMeta({
    required this.id,
    required this.title,
    required this.icon,
    required this.defaultConfig,
    required this.widget,
    this.showInManager = true,
  });
}

/// 📁 看板页面静态数据模型常量与注册表 (Dashboard Static Model & Unified Registry)
class DashboardModel {
  const DashboardModel._();

  // --- Room & Gate IDs ---
  static const String dashboardPageId = 'dashboardPage';

  // --- Active Card Constant IDs (Keep for compatibility) ---
  static const String clockCardId = 'dash_clock';
  static const String poetryCardId = 'dash_poetry';
  static const String systemMonitorCardId = 'dash_system_monitor';
  static const String widgetManagerCardId = 'dash_widget_manager';

  // --- Unified Registry (The ONLY place to change when adding/modifying cards) ---
  static final List<DashboardCardMeta> registry = [
    DashboardCardMeta(
      id: clockCardId,
      title: '极简时钟',
      icon: Icons.access_time_rounded,
      defaultConfig: const DashboardItemConfig(id: clockCardId, x: 0, y: 0, spanX: 4, spanY: 1),
      widget: const ClockView(),
    ),
    DashboardCardMeta(
      id: poetryCardId,
      title: '每日诗词',
      icon: Icons.auto_stories_rounded,
      defaultConfig: const DashboardItemConfig(id: poetryCardId, x: 0, y: 1, spanX: 3, spanY: 2),
      widget: const PoetryView(),
    ),
    DashboardCardMeta(
      id: systemMonitorCardId,
      title: '系统监控',
      icon: Icons.developer_board_rounded,
      defaultConfig: const DashboardItemConfig(id: systemMonitorCardId, x: 0, y: 2, spanX: 4, spanY: 1),
      widget: const SystemMonitorView(),
    ),
    DashboardCardMeta(
      id: widgetManagerCardId,
      title: '中控枢纽',
      icon: Icons.grid_view_rounded,
      defaultConfig: const DashboardItemConfig(id: widgetManagerCardId, x: 0, y: 3, spanX: 4, spanY: 1),
      widget: const WidgetManagerView(),
      showInManager: false, // The manager card doesn't need to show a switch inside itself
    ),
  ];

  static List<String> get activeCardIds => registry.map((c) => c.id).toList();
  static List<DashboardItemConfig> get defaultItems => registry.map((c) => c.defaultConfig).toList();
}
