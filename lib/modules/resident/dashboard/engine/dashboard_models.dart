import 'package:flutter/material.dart';

/// Represents a card's position and size in the grid coordinate system.
class DashboardItemConfig {
  const DashboardItemConfig({
    required this.id,
    required this.x,
    required this.y,
    required this.spanX,
    required this.spanY,
  });

  final String id;
  final int x;
  final int y;
  final int spanX;
  final int spanY;

  DashboardItemConfig copyWith({
    String? id,
    int? x,
    int? y,
    int? spanX,
    int? spanY,
  }) {
    return DashboardItemConfig(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      spanX: spanX ?? this.spanX,
      spanY: spanY ?? this.spanY,
    );
  }

  /// Converts grid coordinates to a Rect for rendering.
  Rect toRect(double unitSize, double gap) {
    final step = unitSize + gap;
    return Rect.fromLTWH(
      x * step,
      y * step,
      spanX * unitSize + (spanX - 1) * gap,
      spanY * unitSize + (spanY - 1) * gap,
    );
  }
}
