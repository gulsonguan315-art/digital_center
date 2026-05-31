import 'package:flutter/material.dart';
import '../layout/grid/grid_extensions.dart';
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
            padding: EdgeInsets.symmetric(
              horizontal: context.units(StageMetrics.paddingHorizontalU),
              vertical: context.units(StageMetrics.paddingVerticalU),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                context.units(StageMetrics.borderRadiusU),
              ),
              clipBehavior: Clip.none, // 🌟 允许卡片外部阴影/高光自然向外延伸，防止在边缘处被生硬切边
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: mainStageContent,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Stack(
            clipBehavior: Clip.none,
            children: overlayStageContent,
          ),
        ),
      ],
    );
  }
}
