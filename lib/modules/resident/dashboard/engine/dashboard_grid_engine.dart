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
      if (!other.enabled) continue; // 🛡️ Ignore disabled cards in collision check
      
      // Standard AABB collision check in grid coordinates
      final overlap = !(x + spanX <= other.x ||
                        x >= other.x + other.spanX ||
                        y + spanY <= other.y ||
                        y >= other.y + other.spanY);
      
      if (overlap) return true;
    }
    return false;
  }

  /// Compacts items upwards to fill gaps, maintaining their relative order and resolving any starting overlaps.
  static List<DashboardItemConfig> applyGravity(List<DashboardItemConfig> items) {
    // 1. Sort by Y then X to process top-to-bottom (with a deterministic ID tie-breaker)
    final sorted = List<DashboardItemConfig>.from(items)
      ..sort((a, b) {
        if (a.y != b.y) return a.y.compareTo(b.y);
        if (a.x != b.x) return a.x.compareTo(b.x);
        return a.id.compareTo(b.id);
      });

    final placed = <DashboardItemConfig>[];

    // 2. First Pass: Settle initial positions. If any item overlaps with already placed items,
    // push it down until it finds a collision-free slot.
    for (final item in sorted) {
      if (!item.enabled) {
        placed.add(item);
        continue;
      }
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
        currentY++; // Resolve overlap by pushing down
      }
      placed.add(item.copyWith(y: currentY));
    }

    // 3. Second Pass: Apply upward gravity compaction to pull everything up tightly
    final results = <DashboardItemConfig>[];
    
    // Sort again to ensure we process top-to-bottom after push-downs (with a deterministic ID tie-breaker)
    placed.sort((a, b) {
      if (a.y != b.y) return a.y.compareTo(b.y);
      if (a.x != b.x) return a.x.compareTo(b.x);
      return a.id.compareTo(b.id);
    });

    for (final item in placed) {
      if (!item.enabled) {
        results.add(item);
        continue;
      }
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
      if (!item.enabled) {
        // Disabled items do not move or receive layout adjustments
        placed.add(item);
        continue;
      }
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
      if (!item.enabled) {
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
