import 'package:flutter/material.dart';
import '../../core/control/superfocus/focus_api.dart';
import '../../core/control/superfocus/focus_manager.dart';
import '../../core/engine/theme/theme_api.dart';
import '../../modules/resident/settings/setting_page.dart';
import '../../modules/resident/dashboard/dashboard_page.dart';
import '../../modules/resident/sidebar/sidebar_view.dart';
import '../../core/layout/stage_metrics.dart';
import '../../core/layout/grid/grid_extensions.dart';

class BuildingPage extends StatelessWidget {
  const BuildingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.appBackground,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();

          // 使用 ValueListenableBuilder 建立全局监听
          // 这种方式不需要在 BuildingMap 里增加任何新的 Room 节点
          return ValueListenableBuilder<FocusTopology>(
            valueListenable: SuperFocusManager.instance.topologyNotifier,
            builder: (context, topology, _) {
              return FocusTopologyScope(
                topology: topology,
                child: Container(
                  color: material.colors.surface,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SidebarView(),
                      Expanded(
                        child: Scaffold(
                          backgroundColor: Colors.transparent,
                          appBar: AppBar(
                            title: null,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                          ),
                          body: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.units(
                                StageMetrics.paddingHorizontalU,
                              ),
                              vertical: context.units(
                                StageMetrics.paddingVerticalU,
                              ),
                            ),
                            child: ValueListenableBuilder<String?>(
                              valueListenable:
                                  SuperFocusManager.instance.intentionRoomId,
                              builder: (context, intentionId, __) =>
                                  _MainContent(intentionId: intentionId),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent({required this.intentionId});

  final String? intentionId;

  @override
  Widget build(BuildContext context) {
    // 信号链路现在是通的
    final showSettings =
        context.useIsActive(SettingPageRoom.roomId) ||
        intentionId == SettingPageRoom.roomId;
    final showDashboard =
        context.useIsActive(DashboardRoom.roomId) ||
        intentionId == DashboardRoom.roomId;

    if (showSettings) {
      return const SettingPageRoom();
    }

    if (showDashboard) {
      return const DashboardRoom();
    }

    return const DashboardRoom();
  }
}
