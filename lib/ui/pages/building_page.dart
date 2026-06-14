import 'package:flutter/material.dart';
import '../../core/engine/theme/theme_api.dart';
import '../../modules/resident/sidebar/sidebar_room.dart';
import '../../core/stage/stage_view.dart';

/// 沉浸式大屏架构：“商管”调度系统 (Stage Manager)
/// 职责：
/// 1. 作为应用的顶级容器，提供背景和基础布局。
/// 2. 组装侧边栏 (Sidebar) 和舞台 (Stage)。
/// 3. ✅ 保持静态：它不再监听信号，信号由内部组件自行处理。
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
            child: Stack(
              children: [
                // 舞台区：由商管系统 (StageView) 内部自动调度，在底层铺满全屏
                // 将 Sidebar 作为中间层注入，实现完美的三明治 Z 轴层级
                const Positioned.fill(
                  child: StageView(
                    sidebar: Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: SidebarRoom(),
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
