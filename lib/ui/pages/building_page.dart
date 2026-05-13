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
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 侧边栏：内部自带 Room 和监听
                SidebarRoom(),
                
                // 舞台区：由商管系统 (StageView) 内部自动调度
                Expanded(
                  child: StageView(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
