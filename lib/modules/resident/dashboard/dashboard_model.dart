/// 📁 看板页面静态数据模型常量 (Dashboard Static Model Constants)
/// 对齐 /settings 的模型分层设计，声明所有 ID 常量，避免在视图中硬编码字符串。
class DashboardModel {
  const DashboardModel._();

  // --- Room & Gate IDs ---
  static const String dashboardPageId = 'dashboardPage';

  // --- Active Card IDs ---
  static const String clockCardId = 'dash_clock';
  static const String poetryCardId = 'dash_poetry';
  static const String systemMonitorCardId = 'dash_system_monitor';
  static const String widgetManagerCardId = 'dash_widget_manager';
}
