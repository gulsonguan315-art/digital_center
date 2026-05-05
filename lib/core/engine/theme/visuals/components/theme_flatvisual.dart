import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_visuals.dart';

class FlatSurfaceEffect extends SurfaceEffect {
  final double borderThickness;
  final double borderOpacity;
  final bool transparentIdle;

  const FlatSurfaceEffect({
    required this.borderThickness,
    required this.borderOpacity,
    this.transparentIdle = false,
  });

  @override
  SurfaceChrome resolve({
    required Color accent,
    required Color border,
    required Color surface,
    required ThemeLayer layer,
    ThemeRole? role, 
  }) {
    return SurfaceChrome(
      borderColor: transparentIdle && layer == ThemeLayer.base
          ? Colors.transparent
          : border.withValues(alpha: borderOpacity),
      borderWidth: borderThickness,
      surfaceOpacity: layer == ThemeLayer.under || !transparentIdle ? 1.0 : 0.0,
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

final flatVisualLayer = ThemeVisualLayer(
  sidebar: const FlatSurfaceEffect(borderThickness: 1.0, borderOpacity: 0.1),
  card: const FlatSurfaceEffect(borderThickness: 1.0, borderOpacity: 0.1),
  appBackground: const FlatSurfaceEffect(
    borderThickness: 1.0,
    borderOpacity: 0.1,
  ),
  button: const FlatSurfaceEffect(borderThickness: 1.5, borderOpacity: 0.12),
  focusGlowRadius: 15.0,
  focusGlowOpacity: 0.4,
);
