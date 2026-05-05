import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme_role.dart';

export '../theme_role.dart';
export '../theme_identity.dart';

import 'components/theme_flatvisual.dart';
import 'components/theme_glassvisual.dart';
import 'components/theme_neumorphvisual.dart';

enum VisualStyle { flat, glass, neumorphic }

@immutable
class SurfaceChrome {
  const SurfaceChrome({
    this.outerShadows = const [],
    this.innerShadows = const [],
    this.borderColor,
    this.borderWidth = 0.0,
    this.borderBlur = 0.0,
    this.surfaceBlur = 0.0,
    this.surfaceOpacity = 1.0,
    this.overlayGradientColors = const [],
    this.innerHighlightColor,
    this.innerHighlightWidth = 0.0,
    this.innerHighlightBlur = 0.0,
  });

  final List<BoxShadow> outerShadows;
  final List<BoxShadow> innerShadows;
  final Color? borderColor;
  final double borderWidth;
  final double borderBlur;
  final double surfaceBlur;
  final double surfaceOpacity;
  final List<Color> overlayGradientColors;
  final Color? innerHighlightColor;
  final double innerHighlightWidth;
  final double innerHighlightBlur;
}

abstract class SurfaceEffect {
  const SurfaceEffect();

  SurfaceChrome resolve({
    required Color accent,
    required Color border,
    required Color surface,
    required ThemeLayer layer,
    ThemeRole? role, // 👈 增加身份证识别接口
  });

  SurfaceEffect lerp(SurfaceEffect other, double t);
}

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

  SurfaceChrome resolve(
    ThemeRole role, {
    required Color accent,
    required Color border,
    required Color surface,
    required ThemeLayer layer,
  }) {
    final effect = switch (role) {
      ThemeRole.sidebar => sidebar,
      ThemeRole.card => card,
      ThemeRole.appBackground => appBackground,
      ThemeRole.button => button,
      ThemeRole.defaultRole => card, // 👈 默认身份使用卡片视觉逻辑
    };
    return effect.resolve(
      accent: accent,
      border: border,
      surface: surface,
      layer: layer,
      role: role, // 👈 将身份证传给餐厅
    );
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
      focusGlowRadius:
          lerpDouble(focusGlowRadius, other.focusGlowRadius, t) ??
          focusGlowRadius,
      focusGlowOpacity:
          lerpDouble(focusGlowOpacity, other.focusGlowOpacity, t) ??
          focusGlowOpacity,
    );
  }
}
