import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_visuals.dart';

class GlassSurfaceEffect extends SurfaceEffect {
  final double blurSigma;
  final double borderOpacity;
  final double surfaceOpacity;

  const GlassSurfaceEffect({
    required this.blurSigma,
    this.borderOpacity = 0.1,
    this.surfaceOpacity = 0.05,
  });

  @override
  SurfaceChrome resolve({
    required Color accent,
    required Color border,
    required Color surface,
    required ThemeLayer layer,
    ThemeRole? role, 
  }) {
    final opacity = layer == ThemeLayer.under
        ? surfaceOpacity * 2.0
        : surfaceOpacity;

    return SurfaceChrome(
      surfaceBlur: blurSigma,
      surfaceOpacity: opacity,
      borderColor: border.withValues(alpha: borderOpacity),
      borderWidth: 1.0,
      overlayGradientColors: [
        Colors.white.withValues(alpha: 0.1),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.05),
      ],
    );
  }

  @override
  SurfaceEffect lerp(SurfaceEffect other, double t) {
    if (other is! GlassSurfaceEffect) return t < 0.5 ? this : other;
    return GlassGlassEffect(
      blurSigma: ui.lerpDouble(blurSigma, other.blurSigma, t) ?? blurSigma,
      borderOpacity:
          ui.lerpDouble(borderOpacity, other.borderOpacity, t) ?? borderOpacity,
      surfaceOpacity:
          ui.lerpDouble(surfaceOpacity, other.surfaceOpacity, t) ??
          surfaceOpacity,
    );
  }
}

// 修正 lerp 里的类名错误
class GlassGlassEffect extends GlassSurfaceEffect {
  const GlassGlassEffect({
    required super.blurSigma,
    super.borderOpacity = 0.1,
    super.surfaceOpacity = 0.05,
  });
}

final glassVisualLayer = ThemeVisualLayer(
  sidebar: const GlassSurfaceEffect(blurSigma: 20, borderOpacity: 0.08),
  card: const GlassSurfaceEffect(blurSigma: 15, borderOpacity: 0.08),
  appBackground: const GlassSurfaceEffect(blurSigma: 0, borderOpacity: 0),
  button: const GlassSurfaceEffect(blurSigma: 10, borderOpacity: 0.12),
  focusGlowRadius: 20.0,
  focusGlowOpacity: 0.3,
);
