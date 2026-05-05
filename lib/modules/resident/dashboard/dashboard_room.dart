import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_api.dart';
import 'dashboard_view.dart';

/// 看板主房间 (Dashboard Main Room)
class DashboardRoom extends StatelessWidget {
  final Widget? child;
  const DashboardRoom({super.key, this.child});

  static const String roomId = 'dashboardPage';

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child ?? const DashboardView());
  }
}
