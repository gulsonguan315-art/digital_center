import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme_role.dart';
import 'components/theme_flatvisual.dart';
import 'components/theme_glassvisual.dart';
import 'components/theme_neumorphvisual.dart';

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
class ThemeVisualLayer extends ThemeExtension<ThemeVisualLayer> {
  const ThemeVisualLayer({
    required this.sidebar,
    required this.card,
    required this.appBackground,
    required this.button,
    required this.focusGlowRadius,
    required this.focusGlowOpacity,
  });

  final SurfaceEffect sidebar;
  final SurfaceEffect card;
  final SurfaceEffect appBackground;
  final SurfaceEffect button;
  final double focusGlowRadius;
  final double focusGlowOpacity;

  factory ThemeVisualLayer.flat() => flatVisualLayer;
  factory ThemeVisualLayer.glass() => glassVisualLayer;
  factory ThemeVisualLayer.neumorphic() => neumorphicVisualLayer;

  SurfaceEffect resolve(ThemeRole role) {
    return switch (role) {
      ThemeRole.sidebar => sidebar,
      ThemeRole.card => card,
      ThemeRole.appBackground => appBackground,
      ThemeRole.button => button,
    };
  }

  @override
  ThemeVisualLayer copyWith({
    SurfaceEffect? sidebar,
    SurfaceEffect? card,
    SurfaceEffect? appBackground,
    SurfaceEffect? button,
    double? focusGlowRadius,
    double? focusGlowOpacity,
  }) {
    return ThemeVisualLayer(
      sidebar: sidebar ?? this.sidebar,
      card: card ?? this.card,
      appBackground: appBackground ?? this.appBackground,
      button: button ?? this.button,
      focusGlowRadius: focusGlowRadius ?? this.focusGlowRadius,
      focusGlowOpacity: focusGlowOpacity ?? this.focusGlowOpacity,
    );
  }

  @override
  ThemeVisualLayer lerp(ThemeExtension<ThemeVisualLayer>? other, double t) {
    if (other is! ThemeVisualLayer) return this;
    return ThemeVisualLayer(
      sidebar: sidebar.lerp(other.sidebar, t),
      card: card.lerp(other.card, t),
      appBackground: appBackground.lerp(other.appBackground, t),
      button: button.lerp(other.button, t),
      focusGlowRadius: lerpDouble(focusGlowRadius, other.focusGlowRadius, t)!,
      focusGlowOpacity: lerpDouble(focusGlowOpacity, other.focusGlowOpacity, t)!,
    );
  }
}
