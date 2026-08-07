import 'package:flutter/material.dart';
import '../../../core/data/models/dashboard_card_definition.dart';
import '../../widgets/clock/clock_view.dart';
import '../../widgets/poetry/poetry_view.dart';
import '../../widgets/system_monitor/system_monitor_view.dart';
import '../../widgets/widget_manager/widget_manager_view.dart';
import '../../widgets/weather/weather_view.dart';
import '../../widgets/aria2/aria2_view.dart';

/// 📂 看板卡片展示元数据 (Dashboard Card Presentation Metadata)
class DashboardCardPresentation {
  final String title;
  final IconData icon;
  final Widget widget;

  const DashboardCardPresentation({
    required this.title,
    required this.icon,
    required this.widget,
  });
}

/// 📁 看板页面展示注册表 (Dashboard UI Registry)
class DashboardModel {
  const DashboardModel._();

  // --- Room & Gate IDs ---
  static const String dashboardPageId = 'dashboardPage';

  static const String widgetManagerCardId = DashboardRegistry.widgetManagerCardId;

  // --- Unified Presentation Registry ---
  static final Map<String, DashboardCardPresentation> presentations = {
    DashboardRegistry.clockCardId: const DashboardCardPresentation(
      title: '极简时钟',
      icon: Icons.access_time_rounded,
      widget: ClockView(),
    ),
    DashboardRegistry.poetryCardId: const DashboardCardPresentation(
      title: '每日诗词',
      icon: Icons.auto_stories_rounded,
      widget: PoetryView(),
    ),
    DashboardRegistry.systemMonitorCardId: const DashboardCardPresentation(
      title: '系统监控',
      icon: Icons.developer_board_rounded,
      widget: SystemMonitorView(),
    ),
    DashboardRegistry.widgetManagerCardId: const DashboardCardPresentation(
      title: '中控枢纽',
      icon: Icons.grid_view_rounded,
      widget: WidgetManagerView(),
    ),
    DashboardRegistry.weatherCardId: const DashboardCardPresentation(
      title: '天气看板',
      icon: Icons.cloud_rounded,
      widget: WeatherView(),
    ),
    DashboardRegistry.aria2CardId: const DashboardCardPresentation(
      title: 'Aria2下载',
      icon: Icons.download_for_offline_rounded,
      widget: Aria2View(),
    ),
  };
}
