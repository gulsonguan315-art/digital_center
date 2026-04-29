import 'package:flutter/material.dart';
import '../../core/control/superfocus/focus_manager.dart';
import '../../core/engine/theme/theme_provider.dart';
import '../../core/engine/theme/theme_colors.dart';
import '../../modules/resident/sidebar/sidebar_view.dart';
import '../../modules/resident/settings/setting_page.dart';

class BuildingPage extends StatelessWidget {
  const BuildingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;

    return Container(
      color: themeColors.backgroundCustom,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 侧边栏：现在处于 Row 的顶层，实现上下顶满视窗
          const SidebarView(),

          // 内容区
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: null,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: _MainContent(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '中心轴心就绪',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
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
