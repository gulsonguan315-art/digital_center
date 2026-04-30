import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_visuals.dart';
import '../theme_colors.dart';

class GlassSurfaceEffect extends SurfaceEffect {
  final double glassBlur;
  final double surfaceOpacity;
  final double borderThickness;
  final bool transparentIdle;

  const GlassSurfaceEffect({
    required this.glassBlur,
    required this.surfaceOpacity,
    required this.borderThickness,
    this.transparentIdle = false,
  });

  @override
  Widget apply(
    BuildContext context,
    Widget child, {
    required bool isFocused,
    bool isWaiting = false,
    BorderRadiusGeometry? borderRadius,
    Color? fillColor,
  }) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;
    final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;
    final radius = borderRadius ?? themeVisuals.defaultRadius;
    final surfaceColor = fillColor ?? themeColors.surfacePanel;

    final Color baseSurface = isWaiting
        ? themeColors.adormColor
        : (transparentIdle ? Colors.transparent : surfaceColor);

    final double effectiveOpacity = (isWaiting || !transparentIdle)
        ? (isWaiting ? 0.8 : surfaceOpacity)
        : 0.0;
    final Color bgColor = baseSurface.withValues(alpha: effectiveOpacity);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: !transparentIdle ? glassBlur : 0.0,
          sigmaY: !transparentIdle ? glassBlur : 0.0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            border: Border.all(
              color: isWaiting
                  ? themeColors.adormColor.withValues(alpha: 0.8)
                  : (transparentIdle
                        ? Colors.transparent
                        : themeColors.surfaceBorder),
              width: borderThickness,
            ),
          ),
          child: Stack(
            children: [
              if (glassBlur > 0 && (isFocused || !transparentIdle))
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
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
      borderThickness:
          ui.lerpDouble(borderThickness, other.borderThickness, t) ??
          borderThickness,
      transparentIdle: t < 0.5 ? transparentIdle : other.transparentIdle,
    );
  }
}

/// 玻璃拟态/亚克力风格预设
ThemeVisuals get glassVisuals => ThemeVisuals(
  buttonSurface: const GlassSurfaceEffect(
    glassBlur: 12.0,
    surfaceOpacity: 0.28,
    borderThickness: 1.5,
  ),
  switchSurface: const GlassSurfaceEffect(
    glassBlur: 10.0,
    surfaceOpacity: 0.24,
    borderThickness: 1.5,
    transparentIdle: true,
  ),
  panelSurface: const GlassSurfaceEffect(
    glassBlur: 18.0,
    surfaceOpacity: 0.38,
    borderThickness: 1.0,
  ),
  defaultRadius: BorderRadius.circular(18),
  focusGlowRadius: 40.0,
  focusGlowOpacity: 0.45,
);
