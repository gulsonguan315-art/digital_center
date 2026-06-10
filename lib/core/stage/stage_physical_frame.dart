import 'package:flutter/material.dart';
import '../layout/grid/grid_extensions.dart';
import '../../modules/resident/sidebar/sidebar_metrics.dart';
import 'stage_metrics.dart';

/// 舞台物理外壳 (纯 UI 容器)
class StagePhysicalFrame extends StatelessWidget {
  final List<Widget> mainStageContent;
  final List<Widget> overlayStageContent;

  const StagePhysicalFrame({
    super.key,
    required this.mainStageContent,
    required this.overlayStageContent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            // 全局拦截区：自动为所有普通房间留出左侧 Sidebar 的空间
            padding: EdgeInsets.only(
              left: context.units(
                StageMetrics.paddingHorizontalU + SidebarMetrics.widthU,
              ),
              right: context.units(StageMetrics.paddingHorizontalU),
              top: context.units(StageMetrics.paddingVerticalU),
              bottom: context.units(StageMetrics.paddingVerticalU),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: mainStageContent,
            ),
          ),
        ),
        Positioned.fill(
          child: Stack(clipBehavior: Clip.none, children: overlayStageContent),
        ),
      ],
    );
  }
}
