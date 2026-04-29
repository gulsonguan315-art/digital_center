import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_visuals.dart';
import '../theme_colors.dart';

class FlatSurfaceEffect extends SurfaceEffect {
  final double borderThickness;
  final bool transparentIdle;

  const FlatSurfaceEffect({
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
  }) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;
    final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;
    final radius = borderRadius ?? themeVisuals.defaultRadius;

    final Color bgColor = isWaiting
        ? themeColors.adormColor
        : (transparentIdle ? Colors.transparent : themeColors.surfacePanel);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: Border.all(
          color: isWaiting
              ? themeColors.adormColor
              : (transparentIdle
                  ? Colors.transparent
                  : themeColors.surfaceBorder),
          width: borderThickness,
        ),
      ),
      child: child,
    );
  }

  @override
  SurfaceEffect lerp(SurfaceEffect other, double t) {
    if (other is! FlatSurfaceEffect) return t < 0.5 ? this : other;
    return FlatSurfaceEffect(
      borderThickness:
          ui.lerpDouble(borderThickness, other.borderThickness, t) ??
          borderThickness,
      transparentIdle: t < 0.5 ? transparentIdle : other.transparentIdle,
    );
  }
}

/// 扁平化风格预设 (类似 Apple 极简设计)
final flatVisuals = ThemeVisuals(
  buttonSurface: const FlatSurfaceEffect(
    borderThickness: 1.5,
  ),
  switchSurface: const FlatSurfaceEffect(
    borderThickness: 1.5,
    transparentIdle: true,
  ),
  defaultRadius: BorderRadius.circular(12),
  focusGlowRadius: 15.0,
  focusGlowOpacity: 0.4,
  sidebar: const SidebarVisual(
    surfaceEffect: NoSidebarSurfaceEffect(),
    activeContentEffect: NoSidebarContentEffect(),
    activeScale: 1.0,
  ),
);
