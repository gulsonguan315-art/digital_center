import 'dart:ui';
import 'package:flutter/material.dart';

enum VisualStyle { flat, glass, neumorphic }

abstract class SurfaceEffect {
  const SurfaceEffect();

  SurfaceChrome resolve({
    required Color accent,
    required Color border,
    required Color surface,
    required SurfaceState state,
  });

  List<Shadow>? foregroundShadows({
    required Color foregroundColor,
    required bool isFocused,
    bool isWaiting = false,
    Color? fillColor,
  }) => null;

  SurfaceEffect lerp(SurfaceEffect other, double t);
}

@immutable
class SurfaceChrome {
  const SurfaceChrome({
    this.outerShadows = const [],
    this.borderColor,
    this.borderWidth = 0,
    this.borderBlur = 0,
    this.innerHighlightColor,
    this.innerHighlightWidth = 0,
    this.innerHighlightBlur = 0,
    this.surfaceBlur = 0,
    this.surfaceOpacity = 1.0,
    this.overlayGradientColors = const [],
  });

  final List<BoxShadow> outerShadows;
  final Color? borderColor;
  final double borderWidth;
  final double borderBlur;
  final Color? innerHighlightColor;
  final double innerHighlightWidth;
  final double innerHighlightBlur;
  final double surfaceBlur;
  final double surfaceOpacity;
  final List<Color> overlayGradientColors;
}

@immutable
class SurfaceState {
  const SurfaceState({
    required this.isFocused,
    this.isWaiting = false,
    this.isConcave = false,
    this.fillColor,
  });

  final bool isFocused;
  final bool isWaiting;
  final bool isConcave;
  final Color? fillColor;
}

@immutable
class ThemeVisuals extends ThemeExtension<ThemeVisuals> {
  final SurfaceEffect buttonSurface;
  final SurfaceEffect switchSurface;
  final SurfaceEffect panelSurface;
  final BorderRadiusGeometry defaultRadius;
  final double focusGlowRadius;
  final double focusGlowOpacity;

  const ThemeVisuals({
    required this.buttonSurface,
    required this.switchSurface,
    required this.panelSurface,
    required this.defaultRadius,
    required this.focusGlowRadius,
    required this.focusGlowOpacity,
  });

  @override
  ThemeVisuals copyWith({
    SurfaceEffect? buttonSurface,
    SurfaceEffect? switchSurface,
    SurfaceEffect? panelSurface,
    BorderRadiusGeometry? defaultRadius,
    double? focusGlowRadius,
    double? focusGlowOpacity,
  }) {
    return ThemeVisuals(
      buttonSurface: buttonSurface ?? this.buttonSurface,
      switchSurface: switchSurface ?? this.switchSurface,
      panelSurface: panelSurface ?? this.panelSurface,
      defaultRadius: defaultRadius ?? this.defaultRadius,
      focusGlowRadius: focusGlowRadius ?? this.focusGlowRadius,
      focusGlowOpacity: focusGlowOpacity ?? this.focusGlowOpacity,
    );
  }

  @override
  ThemeVisuals lerp(ThemeExtension<ThemeVisuals>? other, double t) {
    if (other is! ThemeVisuals) {
      return this;
    }
    return ThemeVisuals(
      buttonSurface: buttonSurface.lerp(other.buttonSurface, t),
      switchSurface: switchSurface.lerp(other.switchSurface, t),
      panelSurface: panelSurface.lerp(other.panelSurface, t),
      defaultRadius:
          BorderRadiusGeometry.lerp(defaultRadius, other.defaultRadius, t) ??
          defaultRadius,
      focusGlowRadius:
          lerpDouble(focusGlowRadius, other.focusGlowRadius, t) ??
          focusGlowRadius,
      focusGlowOpacity:
          lerpDouble(focusGlowOpacity, other.focusGlowOpacity, t) ??
          focusGlowOpacity,
    );
  }
}
