import 'package:flutter/material.dart';

import '../../../core/control/superfocus/focus_api.dart';
import '../../widgets/clock/clock_view.dart';
import '../../widgets/poetry/poetry_view.dart';
import '../../widgets/widget_manager/widget_manager_view.dart';
import 'dashboard_model.dart';
import 'dashboard_view.dart';

/// 📂 看板主入口房间 (Dashboard Room Composition Root)
/// 对齐 /settings 的架构模式，独立负责三级组件组装和依赖注入，将具体的卡片插槽下发给排版 View。
class DashboardRoom extends StatelessWidget {
  final Widget? child;
  const DashboardRoom({super.key, this.child});

  static const String roomId = DashboardModel.dashboardPageId;

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: DashboardModel.dashboardPageId,
      child: child ??
          const DashboardView(
            slots: {
              DashboardModel.clockCardId: ClockView(),
              DashboardModel.poetryCardId: PoetryView(),
              DashboardModel.widgetManagerCardId: WidgetManagerView(),
            },
          ),
    );
  }
}
