import 'package:flutter/material.dart';
import '../layout/grid/grid_extensions.dart';
import '../../modules/resident/sidebar/sidebar_metrics.dart';
import 'stage_metrics.dart';

/// 舞台物理外壳 (纯 UI 容器)
class StagePhysicalFrame extends StatelessWidget {
  final List<Widget> firstFloorContent;
  final List<Widget> secondFloorContent;
  final Widget sidebar;
  final List<Widget> thirdFloorContent;

  const StagePhysicalFrame({
    super.key,
    required this.firstFloorContent,
    required this.secondFloorContent,
    required this.sidebar,
    required this.thirdFloorContent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. 一楼：常规主视图舞台 - 会主动避让 Sidebar 并应用边距，位于底层
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(
              left: context.units(StageMetrics.paddingHorizontalU + SidebarMetrics.widthU),
              right: context.units(StageMetrics.paddingHorizontalU),
              top: context.units(StageMetrics.paddingVerticalU),
              bottom: context.units(StageMetrics.paddingVerticalU),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: firstFloorContent,
            ),
          ),
        ),

        // 2. 二楼：沉浸式大舞台 - 撑满全屏，不避让 Sidebar，覆盖在一楼之上，但在 Sidebar 下方
        Positioned.fill(
          child: Stack(
            clipBehavior: Clip.none,
            children: secondFloorContent,
          ),
        ),
        
        // 3. 中间层：侧边栏 (Sidebar)
        sidebar,

        // 4. 三楼：沉浸式覆盖舞台 - Z轴位于 Sidebar 之上，撑满全屏
        Positioned.fill(
          child: Stack(clipBehavior: Clip.none, children: thirdFloorContent),
        ),
      ],
    );
  }
}
