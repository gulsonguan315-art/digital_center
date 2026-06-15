import 'package:flutter/material.dart';
import 'package:superfocus/core/control/superfocus/navigation/focus_geometry.dart';

enum FocusTransitionMode {
  slide,
  teleport,
}

class FocusReport {
  final Rect rect;
  final FocusGeometry geometry;
  final bool isFocused;
  final bool isPressed;
  final bool isProcessing;
  final BuildContext? context;
  final FocusTransitionMode transitionMode;
  final Duration? teleportDelay;

  const FocusReport({
    required this.rect,
    required this.geometry,
    this.isFocused = false,
    this.isPressed = false,
    this.isProcessing = false,
    this.context,
    this.transitionMode = FocusTransitionMode.slide,
    this.teleportDelay,
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
          context == other.context &&
          transitionMode == other.transitionMode &&
          teleportDelay == other.teleportDelay;

  @override
  int get hashCode =>
      Object.hash(rect, geometry, isFocused, isPressed, isProcessing, context, transitionMode, teleportDelay);
}
