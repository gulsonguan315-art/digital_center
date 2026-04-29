import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_visuals.dart';
import '../theme_colors.dart';

class NeumorphSurfaceEffect extends SurfaceEffect {
  final double borderThickness;
  final bool transparentIdle;
  final List<BoxShadow>? focusedShadows;

  const NeumorphSurfaceEffect({
    required this.borderThickness,
    this.focusedShadows,
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
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
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
        boxShadow: isWaiting ? (focusedShadows ?? []) : [],
      ),
      child: child,
    );
  }

  @override
  SurfaceEffect lerp(SurfaceEffect other, double t) {
    if (other is! NeumorphSurfaceEffect) return t < 0.5 ? this : other;
    return NeumorphSurfaceEffect(
      borderThickness:
          ui.lerpDouble(borderThickness, other.borderThickness, t) ??
          borderThickness,
      focusedShadows: BoxShadow.lerpList(focusedShadows, other.focusedShadows, t),
      transparentIdle: t < 0.5 ? transparentIdle : other.transparentIdle,
    );
  }
}

final neumorphicVisuals = ThemeVisuals(
  buttonSurface: const NeumorphSurfaceEffect(
    borderThickness: 0.5,
    focusedShadows: [
      BoxShadow(
        color: Color.fromARGB(120, 0, 0, 0),
        offset: Offset(4, 4),
        blurRadius: 8,
      ),
      BoxShadow(
        color: Color.fromARGB(100, 255, 255, 255),
        offset: Offset(-4, -4),
        blurRadius: 8,
      ),
    ],
  ),
  switchSurface: const NeumorphSurfaceEffect(
    borderThickness: 0.5,
    transparentIdle: true,
  ),
  defaultRadius: BorderRadius.circular(24),
  focusGlowRadius: 30.0,
  focusGlowOpacity: 0.2,
  sidebar: const SidebarVisual(
    surfaceEffect: NeumorphSidebarSurfaceEffect(
      keyShadowColor: Color.fromARGB(120, 0, 0, 0),
      keyShadowOffset: Offset(6, 6),
      keyShadowBlur: 8.4,
      ambientShadowColor: Color.fromARGB(100, 255, 255, 255),
      ambientShadowOffset: Offset(-6, -6),
      ambientShadowBlur: 6.0,
      borderColor: Color.fromARGB(15, 255, 255, 255),
      borderWidth: 1.0,
    ),
    activeContentEffect: NeumorphSidebarContentEffect(
      keyShadowColor: Color.fromARGB(77, 0, 0, 0),
      keyShadowOffset: Offset(2, 2),
      keyShadowBlur: 6.0,
      glowOpacity: 0.3,
      glowOffset: Offset(1.5, 1.5),
      glowBlur: 4.0,
    ),
    activeScale: 1.08,
  ),
);
