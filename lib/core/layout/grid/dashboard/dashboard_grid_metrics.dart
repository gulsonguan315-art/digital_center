import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:superfocus/core/layout/grid/grid_context.dart';
//负责基于 GridContext.u 生成看板当前的 tile 尺寸和间距

@immutable
class DashboardGridMetrics {
  const DashboardGridMetrics({
    required this.baseTileSize,
    required this.tileSpacing,
  });

  factory DashboardGridMetrics.fromGridContext(GridContext gridContext) {
    return DashboardGridMetrics(
      // 1080p baseline: 140 / 10.8 = 12.9629u
      baseTileSize: gridContext.units(_baseTileUnits),
      // 1080p baseline: 24 / 10.8 = 2.2222u
      tileSpacing: gridContext.units(_tileSpacingUnits),
    );
  }

  static const double _baseTileUnits = 12.962962963;
  static const double _tileSpacingUnits = 2.222222222;

  final double baseTileSize;
  final double tileSpacing;

  double get step => baseTileSize + tileSpacing;

  int resolveColumnCount(double availableWidth) {
    if (availableWidth <= 0 || step <= 0) return 1;
    return (((availableWidth + tileSpacing) / step).floor()).clamp(1, 1000)
        .toInt();
  }

  Offset resolveGridCoord(Offset pixels) {
    if (step <= 0) return Offset.zero;
    final x = (pixels.dx / step).round();
    final y = (pixels.dy / step).round();
    return Offset(x.toDouble(), y.toDouble());
  }

  int resolveSpanX(Size size, int columns) {
    if (step <= 0) return 1;
    return (((size.width + tileSpacing) / step).round()).clamp(1, columns)
        .toInt();
  }

  int resolveSpanY(Size size) {
    if (step <= 0) return 1;
    return (((size.height + tileSpacing) / step).round()).clamp(1, 1000)
        .toInt();
  }
}
