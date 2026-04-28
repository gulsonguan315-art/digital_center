import 'package:flutter/material.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_layout_models.dart';

//碰撞检测，重力压缩，基础 Rect 数学
/// Dashboard-specific legacy grid engine.
/// It will be gradually reduced to pure geometry and collision logic.
class DashboardGridEngine {
  static bool checkCollision(
    String moduleId,
    int x,
    int y,
    int spanX,
    int spanY,
    List<ModuleConfig> configs,
  ) {
    for (final other in configs) {
      if (other.moduleId == moduleId) continue;
      final overlap =
          !(x + spanX <= other.x ||
              x >= other.x + other.spanX ||
              y + spanY <= other.y ||
              y >= other.y + other.spanY);
      if (overlap) return true;
    }
    return false;
  }

  static List<ModuleConfig> applyGravity(
    List<ModuleConfig> configs, {
    required ModuleConfig Function(ModuleConfig config, int newY) updateY,
  }) {
    final sorted = List<ModuleConfig>.from(configs)
      ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

    final results = <ModuleConfig>[];

    for (final config in sorted) {
      var currentY = config.y;

      while (currentY > 0) {
        final nextY = currentY - 1;
        final collision = checkCollision(
          config.moduleId,
          config.x,
          nextY,
          config.spanX,
          config.spanY,
          results,
        );
        if (collision) break;
        currentY = nextY;
      }
      results.add(updateY(config, currentY));
    }

    return results;
  }

  static Rect calculateRect({
    required int x,
    required int y,
    required int spanX,
    required int spanY,
    required double baseTileSize,
    required double tileSpacing,
  }) {
    final step = baseTileSize + tileSpacing;
    return Rect.fromLTWH(
      x * step,
      y * step,
      spanX * baseTileSize + (spanX - 1) * tileSpacing,
      spanY * baseTileSize + (spanY - 1) * tileSpacing,
    );
  }
}
