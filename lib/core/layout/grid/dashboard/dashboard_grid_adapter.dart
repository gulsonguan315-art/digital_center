import 'package:flutter/material.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_grid_engine.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_layout_models.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_grid_metrics.dart';
import 'package:superfocus/core/layout/grid/grid_context.dart';
//负责：列数计算，排序，ModuleConfig -> Rect，预览态 Rect，像素 -> 网格坐标，尺寸 -> spanX/spanY

@immutable
class DashboardGridPlacement {
  const DashboardGridPlacement({required this.x, required this.y});

  final int x;
  final int y;
}

@immutable
class DashboardGridSpan {
  const DashboardGridSpan({required this.spanX, required this.spanY});

  final int spanX;
  final int spanY;
}

/// Read-only bridge between the dashboard view shell and legacy layout math.
/// It centralizes geometry, ordering and interaction math away from the page widget.
class DashboardGridAdapter {
  const DashboardGridAdapter._();

  static DashboardGridMetrics resolveMetrics(GridContext gridContext) {
    return DashboardGridMetrics.fromGridContext(gridContext);
  }

  static int resolveGridColumns({
    required double availableWidth,
    required GridContext gridContext,
  }) {
    return resolveMetrics(gridContext).resolveColumnCount(availableWidth);
  }

  static List<ModuleConfig> sortConfigsForEntry(
    Iterable<ModuleConfig> configs,
  ) {
    final sorted = List<ModuleConfig>.from(configs);
    sorted.sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));
    return sorted;
  }

  static Rect resolveBaseRect(
    ModuleConfig config, {
    required GridContext gridContext,
  }) {
    final metrics = resolveMetrics(gridContext);
    return DashboardGridEngine.calculateRect(
      x: config.x,
      y: config.y,
      spanX: config.spanX,
      spanY: config.spanY,
      baseTileSize: metrics.baseTileSize,
      tileSpacing: metrics.tileSpacing,
    );
  }

  static Rect resolvePreviewRect({
    required Rect baseRect,
    Offset? previewOffset,
    Size? previewSize,
  }) {
    return Rect.fromLTWH(
      previewOffset?.dx ?? baseRect.left,
      previewOffset?.dy ?? baseRect.top,
      previewSize?.width ?? baseRect.width,
      previewSize?.height ?? baseRect.height,
    );
  }

  static DashboardGridPlacement resolvePlacementFromPixels(
    Offset pixels, {
    required DashboardGridMetrics metrics,
  }) {
    final gridCoord = metrics.resolveGridCoord(pixels);
    return DashboardGridPlacement(
      x: gridCoord.dx.toInt(),
      y: gridCoord.dy.toInt(),
    );
  }

  static DashboardGridSpan resolveSpanFromSize(
    Size size, {
    required int columns,
    required DashboardGridMetrics metrics,
  }) {
    return DashboardGridSpan(
      spanX: metrics.resolveSpanX(size, columns),
      spanY: metrics.resolveSpanY(size),
    );
  }
}
