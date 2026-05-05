import 'package:flutter/material.dart';
import 'engine/dashboard_controller.dart';
import 'engine/dashboard_models.dart';

/// Business logic for Dashboard interactions (Drag, Resize, etc.)
class DashboardCallback {
  const DashboardCallback._();

  /// Handles card movement during drag.
  static void onItemDrag({
    required DashboardController controller,
    required GlobalKey gridKey,
    required DragUpdateDetails details,
    required String id,
    required double unitSize,
    required double gap,
  }) {
    if (!controller.isEditMode) return;

    final RenderBox? gridBox =
        gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final Offset localPos = gridBox.globalToLocal(details.globalPosition);

    // Calculate grid coordinates
    final int targetX = (localPos.dx / (unitSize + gap)).floor();
    final int targetY = (localPos.dy / (unitSize + gap)).floor();

    // Boundary check (Assuming 12 columns for now)
    if (targetX >= 0 && targetY >= 0 && targetX < 12) {
      controller.updateItemPosition(id, targetX, targetY);
    }
  }

  /// Handles card resizing during handle drag.
  static void onItemResize({
    required DashboardController controller,
    required GlobalKey gridKey,
    required DragUpdateDetails details,
    required DashboardItemConfig config,
    required Rect rect,
    required double unitSize,
    required double gap,
  }) {
    final RenderBox? gridBox =
        gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    // Calculate finger position relative to card top-left
    final Offset localPos = gridBox.globalToLocal(details.globalPosition);
    final double relativeX = localPos.dx - rect.left;
    final double relativeY = localPos.dy - rect.top;

    // Convert pixel distance to grid spans
    final int targetSpanX = (relativeX / (unitSize + gap)).round();
    final int targetSpanY = (relativeY / (unitSize + gap)).round();

    controller.updateItemSpan(config.id, targetSpanX, targetSpanY);
  }

  /// Finalizes any interaction.
  static void onInteractionEnd(DashboardController controller) {
    controller.finalizeLayout();
  }
}
