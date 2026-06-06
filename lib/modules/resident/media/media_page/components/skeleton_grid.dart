import 'package:flutter/material.dart';
import 'package:superfocus/core/layout/grid/grid_extensions.dart';
import '../../../../../core/engine/theme/theme_api.dart';

/// 骨架屏：加载中时显示灰色占位卡片
class SkeletonGrid extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final double gap;
  final double aspectRatio;

  const SkeletonGrid({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.gap,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double rawCols = (constraints.maxWidth + gap) / (cardWidth + gap);
        final int cols = rawCols.floor().clamp(1, 100);

        return GridView.builder(
          padding: EdgeInsets.only(bottom: context.units(4)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: aspectRatio,
          ),
          itemCount: cols * 3, // 显示约 3 行骨架
          itemBuilder: (context, index) {
            return Builder(
              builder: (ctx) {
                final colors = ctx.useTheme().colors;
                return Container(
                  decoration: BoxDecoration(
                    color: colors.backgroundFocused.withValues(alpha: 0.5),
                    borderRadius: ctx.useTheme().shape.radius,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
