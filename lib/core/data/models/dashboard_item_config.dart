import 'package:flutter/material.dart';

/// Represents a card's position and size in the grid coordinate system.
class DashboardItemConfig {
  const DashboardItemConfig({
    required this.id,
    required this.x,
    required this.y,
    required this.spanX,
    required this.spanY,
    this.enabled = true,
  });

  final String id;
  final int x;
  final int y;
  final int spanX;
  final int spanY;
  final bool enabled;

  DashboardItemConfig copyWith({
    String? id,
    int? x,
    int? y,
    int? spanX,
    int? spanY,
    bool? enabled,
  }) {
    return DashboardItemConfig(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      spanX: spanX ?? this.spanX,
      spanY: spanY ?? this.spanY,
      enabled: enabled ?? this.enabled,
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

  /// Converts entity to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'spanX': spanX,
      'spanY': spanY,
      'enabled': enabled,
    };
  }

  /// Restores entity from a JSON map.
  factory DashboardItemConfig.fromJson(Map<String, dynamic> json) {
    return DashboardItemConfig(
      id: json['id'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      spanX: json['spanX'] as int,
      spanY: json['spanY'] as int,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardItemConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          x == other.x &&
          y == other.y &&
          spanX == other.spanX &&
          spanY == other.spanY &&
          enabled == other.enabled;

  @override
  int get hashCode =>
      id.hashCode ^
      x.hashCode ^
      y.hashCode ^
      spanX.hashCode ^
      spanY.hashCode ^
      enabled.hashCode;
}
