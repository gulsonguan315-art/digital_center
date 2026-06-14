import 'package:flutter/material.dart';

import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/stage/stage_contract.dart';
import '../../../core/stage/stage_models.dart';
import '../../../core/stage/stage_registry.dart';
import 'dashboard_model.dart';
import 'dashboard_view.dart';

/// 📂 看板主入口房间 (Dashboard Room Composition Root)
/// 对齐 /settings 的架构模式，独立负责三级组件组装 and 依赖注入，将具体的卡片插槽下发给排版 View。
class DashboardRoom extends StatelessWidget {
  final Widget? child;
  const DashboardRoom({super.key, this.child});

  static const String roomId = DashboardModel.dashboardPageId;

  static void register() {
    StageRegistry.register(
      StageContract(
        roomId: roomId,
        zone: StageZone.firstFloor_main,
        keepAlive: true,
        builder: (context) => const DashboardRoom(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: DashboardModel.dashboardPageId,
      child: child ??
          DashboardView(
            slots: {
              for (final entry in DashboardModel.presentations.entries) entry.key: entry.value.widget,
            },
          ),
    );
  }
}
