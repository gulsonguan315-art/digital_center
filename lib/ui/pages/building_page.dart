import 'package:flutter/material.dart';
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

          return Container(
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
                        horizontal: context.units(StageMetrics.paddingHorizontalU),
                        vertical: context.units(StageMetrics.paddingVerticalU),
                      ),
                      child: const _MainContent(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    final colors = context.useTheme().colors;

    return ValueListenableBuilder<FocusTopology>(
      valueListenable: SuperFocusManager.instance.topologyNotifier,
      builder: (context, topology, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: SuperFocusManager.instance.intentionRoomId,
          builder: (context, intentionId, _) {
            final showSettings =
                topology.activePath.contains(SettingPageRoom.roomId) ||
                intentionId == SettingPageRoom.roomId;

            if (showSettings) {
              return const SettingPageRoom();
            }

            final showDashboard =
                topology.activePath.contains(DashboardRoom.roomId) ||
                intentionId == DashboardRoom.roomId;

            if (showDashboard) {
              return const DashboardRoom();
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 64,
                    color: colors.textPrimary.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '中心轴心就绪',
                    style: TextStyle(
                      color: colors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 20,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
