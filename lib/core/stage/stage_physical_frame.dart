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
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  children: mainStageContent,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: overlayStageContent,
            ),
          ),
        ),
      ],
    );
  }
}
