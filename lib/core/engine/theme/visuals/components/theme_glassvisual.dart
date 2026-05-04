import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_visuals.dart';

// =============================================================================
// 第一部分: 材质算法 (Effect Implementation)
// =============================================================================

class GlassSurfaceEffect extends SurfaceEffect {
  final double glassBlur;
  final double surfaceOpacity;
  final double borderOpacity;
  final double borderThickness;
  final bool transparentIdle;

  const GlassSurfaceEffect({
    required this.glassBlur,
    required this.surfaceOpacity,
    this.borderOpacity = 0.12,
    required this.borderThickness,
    this.transparentIdle = false,
  });

  @override
  SurfaceChrome resolve({
    required Color accent,
    required Color border,
    required Color surface,
    required SurfaceState state,
  }) {
    return SurfaceChrome(
      borderColor: state.isWaiting
          ? accent.withValues(alpha: 0.8)
          : (transparentIdle
                ? Colors.transparent
                : border.withValues(alpha: borderOpacity)),
      borderWidth: borderThickness,
      surfaceBlur: !transparentIdle ? glassBlur : 0.0,
      surfaceOpacity: (state.isWaiting || !transparentIdle)
          ? (state.isWaiting ? 0.8 : surfaceOpacity)
          : 0.0,
      overlayGradientColors:
          glassBlur > 0 && (state.isFocused || !transparentIdle)
          ? [
              Colors.white.withValues(alpha: 0.15),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.02),
            ]
          : const [],
    );
  }

  @override
  SurfaceEffect lerp(SurfaceEffect other, double t) {
    if (other is! GlassSurfaceEffect) return t < 0.5 ? this : other;
    return GlassSurfaceEffect(
      glassBlur: ui.lerpDouble(glassBlur, other.glassBlur, t) ?? glassBlur,
      surfaceOpacity:
          ui.lerpDouble(surfaceOpacity, other.surfaceOpacity, t) ??
          surfaceOpacity,
      borderOpacity:
          ui.lerpDouble(borderOpacity, other.borderOpacity, t) ?? borderOpacity,
      borderThickness:
          ui.lerpDouble(borderThickness, other.borderThickness, t) ??
          borderThickness,
      transparentIdle: t < 0.5 ? transparentIdle : other.transparentIdle,
    );
  }
}

// =============================================================================
// 第二部分: 实例配置 (Layer Instance)
// =============================================================================

final glassVisualLayer = ThemeVisualLayer(
  sidebar: const GlassSurfaceEffect(
    glassBlur: 18.0,
    surfaceOpacity: 0.38,
    borderOpacity: 0.08,
    borderThickness: 1.0,
  ),
  card: const GlassSurfaceEffect(
    glassBlur: 18.0,
    surfaceOpacity: 0.38,
    borderOpacity: 0.08,
    borderThickness: 1.0,
  ),
  appBackground: const GlassSurfaceEffect(
    glassBlur: 18.0,
    surfaceOpacity: 0.38,
    borderOpacity: 0.08,
    borderThickness: 1.0,
  ),
  button: const GlassSurfaceEffect(
    glassBlur: 12.0,
    surfaceOpacity: 0.28,
    borderOpacity: 0.12,
    borderThickness: 1.5,
  ),
  focusGlowRadius: 40.0,
  focusGlowOpacity: 0.45,
);
