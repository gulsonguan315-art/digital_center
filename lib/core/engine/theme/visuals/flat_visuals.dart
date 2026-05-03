import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_visuals.dart';
import '../theme_colors.dart';

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

    final Color bgColor = isWaiting
        ? themeColors.adormColor
        : (transparentIdle ? Colors.transparent : surfaceColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: borderThickness > 0
            ? Border.all(
                color: isWaiting
                    ? themeColors.adormColor
                    : (transparentIdle
                        ? Colors.transparent
                        : themeColors.surfaceBorder.withValues(alpha: borderOpacity)),
                width: borderThickness,
              )
            : null,
      ),
      child: child,
    );
  }

  @override
  SurfaceChrome chrome({
    required BuildContext context,
    required bool isFocused,
    bool isWaiting = false,
    Color? fillColor,
  }) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;
    return SurfaceChrome(
      borderColor: isWaiting
          ? themeColors.adormColor
          : (transparentIdle
              ? Colors.transparent
              : themeColors.surfaceBorder.withValues(alpha: borderOpacity)),
      borderWidth: borderThickness,
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
          ui.lerpDouble(borderOpacity, other.borderOpacity, t) ??
          borderOpacity,
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
