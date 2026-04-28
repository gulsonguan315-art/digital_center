import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:superfocus/core/layout/grid/grid_breakpoints.dart';
import 'package:superfocus/core/layout/grid/grid_math.dart';
import 'package:superfocus/core/layout/grid/grid_spec.dart';

@immutable
/// GridContext 是运行时真值源。
/// 它把当前视口映射成统一的 `u`、动态列数和断点语义。
class GridContext {
  const GridContext({
    required this.viewportSize,
    required this.spec,
    required this.unit,
    required this.columnCount,
    required this.aspectRatio,
    required this.breakpoint,
  });

  factory GridContext.fromViewport(
    Size viewportSize, {
    GridSpec spec = GridSpec.standard,
  }) {
    final aspectRatio =
        viewportSize.height <= 0 ? 0.0 : viewportSize.width / viewportSize.height;
    return GridContext(
      viewportSize: viewportSize,
      spec: spec,
      unit: spec.computeUnit(viewportSize.height),
      columnCount: spec.computeColumnCount(
        viewportWidth: viewportSize.width,
        viewportHeight: viewportSize.height,
      ),
      aspectRatio: aspectRatio,
      breakpoint: spec.resolveBreakpoint(aspectRatio),
    );
  }

  final Size viewportSize;
  final GridSpec spec;
  final double unit;
  final int columnCount;
  final double aspectRatio;
  final GridBreakpoint breakpoint;

  double get viewportWidth => viewportSize.width;
  double get viewportHeight => viewportSize.height;

  double units(double value) => GridMath.unitsToPixels(value, unit);

  double columns(double value) => value * unit;

  double get pageInset => units(spec.pageInsetUnits);

  double get sectionGap => units(spec.sectionGapUnits);

  double get contentWidth =>
      ((viewportWidth - pageInset * 2).clamp(0.0, double.infinity) as num)
          .toDouble();

  double get contentHeight =>
      ((viewportHeight - pageInset * 2).clamp(0.0, double.infinity) as num)
          .toDouble();

  int semanticSpanToRuntime(int semanticSpan) {
    return GridMath.semanticSpanToRuntime(
      semanticSpan: semanticSpan,
      semanticColumns: spec.semanticColumns,
      runtimeColumns: columnCount,
    );
  }

  int semanticOffsetToRuntime(int semanticOffset) {
    return GridMath.runtimeOffsetToColumns(
      semanticOffset: semanticOffset,
      semanticColumns: spec.semanticColumns,
      runtimeColumns: columnCount,
    );
  }
}
