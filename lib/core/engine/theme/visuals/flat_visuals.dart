import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_visuals.dart';

class FlatSurfaceEffect extends SurfaceEffect {
  final double borderThickness;
  final double borderOpacity;
  final bool transparentIdle;

  const FlatSurfaceEffect({
    required this.borderThickness,
    this.borderOpacity = 0.12,
    this.transparentIdle = false,
  });

  @override
  @override
  SurfaceChrome resolve({
    required Color accent,
    required Color border,
    required Color surface,
    required SurfaceState state,
  }) {
    return SurfaceChrome(
      borderColor: state.isWaiting
          ? accent
          : (transparentIdle
                ? Colors.transparent
                : border.withValues(alpha: borderOpacity)),
      borderWidth: borderThickness,
      surfaceOpacity: state.isWaiting || !transparentIdle ? 1.0 : 0.0,
    );
  }

  @override
  SurfaceEffect lerp(SurfaceEffect other, double t) {
    if (other is! FlatSurfaceEffect) return t < 0.5 ? this : other;
    return FlatSurfaceEffect(
      borderThickness:
          ui.lerpDouble(borderThickness, other.borderThickness, t) ??
          borderThickness,
      borderOpacity:
          ui.lerpDouble(borderOpacity, other.borderOpacity, t) ?? borderOpacity,
      transparentIdle: t < 0.5 ? transparentIdle : other.transparentIdle,
    );
  }
}

/// 扁平化风格预设 (类似 Apple 极简设计)
ThemeVisuals get flatVisuals => ThemeVisuals(
  buttonSurface: const FlatSurfaceEffect(
    borderThickness: 1.5,
    borderOpacity: 0.12,
  ),
  switchSurface: const FlatSurfaceEffect(
    borderThickness: 1.5,
    borderOpacity: 0.12,
    transparentIdle: true,
  ),
  panelSurface: const FlatSurfaceEffect(
    borderThickness: 1.0,
    borderOpacity: 0.1,
  ),
  defaultRadius: BorderRadius.circular(12),
  focusGlowRadius: 15.0,
  focusGlowOpacity: 0.4,
);
