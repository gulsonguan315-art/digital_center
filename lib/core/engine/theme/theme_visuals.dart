import 'dart:ui';
import 'package:flutter/material.dart';

enum VisualStyle { flat, glass, neumorphic }

@immutable
class ThemeVisuals extends ThemeExtension<ThemeVisuals> {
  final double glassBlur;
  final double surfaceOpacity;
  final BorderRadiusGeometry defaultRadius;
  final double borderThickness;
  final double focusGlowRadius;
  final double focusGlowOpacity;

  const ThemeVisuals({
    required this.glassBlur,
    required this.surfaceOpacity,
    required this.defaultRadius,
    required this.borderThickness,
    required this.focusGlowRadius,
    required this.focusGlowOpacity,
  });

  @override
  ThemeVisuals copyWith({
    double? glassBlur,
    double? surfaceOpacity,
    BorderRadiusGeometry? defaultRadius,
    double? borderThickness,
    double? focusGlowRadius,
    double? focusGlowOpacity,
  }) {
    return ThemeVisuals(
      glassBlur: glassBlur ?? this.glassBlur,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      defaultRadius: defaultRadius ?? this.defaultRadius,
      borderThickness: borderThickness ?? this.borderThickness,
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
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t) ?? glassBlur,
      surfaceOpacity:
          lerpDouble(surfaceOpacity, other.surfaceOpacity, t) ?? surfaceOpacity,
      defaultRadius:
          BorderRadiusGeometry.lerp(defaultRadius, other.defaultRadius, t) ??
          defaultRadius,
      borderThickness:
          lerpDouble(borderThickness, other.borderThickness, t) ??
          borderThickness,
      focusGlowRadius:
          lerpDouble(focusGlowRadius, other.focusGlowRadius, t) ??
          focusGlowRadius,
      focusGlowOpacity:
          lerpDouble(focusGlowOpacity, other.focusGlowOpacity, t) ??
          focusGlowOpacity,
    );
  }
}
