import 'package:flutter/material.dart';
import '../../../ui/visual/cursor/focus_geometry.dart';

class FocusReport {
  final Rect rect;
  final FocusGeometry geometry;
  final bool isFocused;
  final bool isPressed;
  final bool isProcessing;
  final BuildContext? context;

  const FocusReport({
    required this.rect,
    required this.geometry,
    this.isFocused = false,
    this.isPressed = false,
    this.isProcessing = false,
    this.context,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusReport &&
          rect == other.rect &&
          geometry == other.geometry &&
          isFocused == other.isFocused &&
          isPressed == other.isPressed &&
          isProcessing == other.isProcessing &&
          context == other.context;

  @override
  int get hashCode =>
      Object.hash(rect, geometry, isFocused, isPressed, isProcessing, context);
}
