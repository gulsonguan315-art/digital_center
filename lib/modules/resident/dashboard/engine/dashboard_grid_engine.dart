import 'dashboard_models.dart';

/// Pure logic engine for collision detection and gravity compaction.
class DashboardGridEngine {
  const DashboardGridEngine._();

  /// Checks if a proposed position/size overlaps with any existing items.
  static bool checkCollision({
    required String id,
    required int x,
    required int y,
    required int spanX,
    required int spanY,
    required List<DashboardItemConfig> items,
  }) {
    for (final other in items) {
      if (other.id == id) continue;
      
      // Standard AABB collision check in grid coordinates
      final overlap = !(x + spanX <= other.x ||
                        x >= other.x + other.spanX ||
                        y + spanY <= other.y ||
                        y >= other.y + other.spanY);
      
      if (overlap) return true;
    }
    return false;
  }

  /// Compacts items upwards to fill gaps, maintaining their relative order.
  static List<DashboardItemConfig> applyGravity(List<DashboardItemConfig> items) {
    // Sort by Y then X to process top-to-bottom
    final sorted = List<DashboardItemConfig>.from(items)
      ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

    final results = <DashboardItemConfig>[];

    for (final item in sorted) {
      var currentY = item.y;

      // Try moving up until a collision occurs or we hit the top
      while (currentY > 0) {
        final nextY = currentY - 1;
        final collision = checkCollision(
          id: item.id,
          x: item.x,
          y: nextY,
          spanX: item.spanX,
          spanY: item.spanY,
          items: results,
        );
        if (collision) break;
        currentY = nextY;
      }
      results.add(item.copyWith(y: currentY));
    }

    return results;
  }
}
