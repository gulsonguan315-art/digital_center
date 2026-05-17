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

  /// Adjusts the layout when an item is being actively dragged, moved, or resized.
  /// The active item is treated as a fixed obstacle, and colliding items are pushed down.
  static List<DashboardItemConfig> adjustLayout(
    List<DashboardItemConfig> items,
    String activeId,
  ) {
    // 1. Separate the active item and other items
    final activeItem = items.firstWhere((item) => item.id == activeId);
    final otherItems = items.where((item) => item.id != activeId).toList();

    // 2. Sort other items from top to bottom
    otherItems.sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

    // 3. The active item is placed first as an immovable obstacle
    final placed = <DashboardItemConfig>[activeItem];

    // 4. Place other items, pushing them down if they collide with already placed items
    for (final item in otherItems) {
      var currentY = item.y;
      while (true) {
        final hasCollision = checkCollision(
          id: item.id,
          x: item.x,
          y: currentY,
          spanX: item.spanX,
          spanY: item.spanY,
          items: placed,
        );
        if (!hasCollision) break;
        currentY++; // Push down by 1 unit
      }
      placed.add(item.copyWith(y: currentY));
    }

    // 5. Compact non-active items upwards as much as possible
    final sortedPlaced = List<DashboardItemConfig>.from(placed)
      ..sort((a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

    final compacted = <DashboardItemConfig>[];
    for (final item in sortedPlaced) {
      if (item.id == activeId) {
        compacted.add(item);
        continue;
      }

      var currentY = item.y;
      while (currentY > 0) {
        final nextY = currentY - 1;
        final collision = checkCollision(
          id: item.id,
          x: item.x,
          y: nextY,
          spanX: item.spanX,
          spanY: item.spanY,
          items: compacted,
        );
        if (collision) break;
        currentY = nextY;
      }
      compacted.add(item.copyWith(y: currentY));
    }

    return compacted;
  }
}
