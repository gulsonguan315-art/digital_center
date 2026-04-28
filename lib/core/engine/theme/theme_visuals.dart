import 'dart:ui';
import 'package:flutter/material.dart';

enum VisualStyle { flat, glass, neumorphic, grass }

@immutable
class ThemeVisuals extends ThemeExtension<ThemeVisuals> {
  final double glassBlur;
  final double surfaceOpacity;
  final BorderRadiusGeometry defaultRadius;
  final double borderThickness;
  final double focusGlowRadius;
  final double focusGlowOpacity;
  final SidebarVisual sidebar;

  const ThemeVisuals({
    required this.glassBlur,
    required this.surfaceOpacity,
    required this.defaultRadius,
    required this.borderThickness,
    required this.focusGlowRadius,
    required this.focusGlowOpacity,
    required this.sidebar,
  });

  @override
  ThemeVisuals copyWith({
    double? glassBlur,
    double? surfaceOpacity,
    BorderRadiusGeometry? defaultRadius,
    double? borderThickness,
    double? focusGlowRadius,
    double? focusGlowOpacity,
    SidebarVisual? sidebar,
  }) {
    return ThemeVisuals(
      glassBlur: glassBlur ?? this.glassBlur,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      defaultRadius: defaultRadius ?? this.defaultRadius,
      borderThickness: borderThickness ?? this.borderThickness,
      focusGlowRadius: focusGlowRadius ?? this.focusGlowRadius,
      focusGlowOpacity: focusGlowOpacity ?? this.focusGlowOpacity,
      sidebar: sidebar ?? this.sidebar,
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
      sidebar: sidebar.lerp(other.sidebar, t),
    );
  }
}

@immutable
class SidebarVisual {
  final SidebarSurfaceEffect surfaceEffect;
  final SidebarContentEffect activeContentEffect;
  final double activeScale;

  const SidebarVisual({
    required this.surfaceEffect,
    required this.activeContentEffect,
    required this.activeScale,
  });

  SidebarVisual lerp(SidebarVisual other, double t) {
    return SidebarVisual(
      surfaceEffect: surfaceEffect.lerp(other.surfaceEffect, t),
      activeContentEffect: activeContentEffect.lerp(
        other.activeContentEffect,
        t,
      ),
      activeScale: lerpDouble(activeScale, other.activeScale, t) ?? activeScale,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SidebarVisual &&
          surfaceEffect == other.surfaceEffect &&
          activeContentEffect == other.activeContentEffect &&
          activeScale == other.activeScale;

  @override
  int get hashCode =>
      Object.hash(surfaceEffect, activeContentEffect, activeScale);
}

sealed class SidebarSurfaceEffect {
  const SidebarSurfaceEffect();

  SidebarSurfaceEffect lerp(SidebarSurfaceEffect other, double t) {
    return t < 0.5 ? this : other;
  }
}

@immutable
class NoSidebarSurfaceEffect extends SidebarSurfaceEffect {
  const NoSidebarSurfaceEffect();

  @override
  bool operator ==(Object other) => other is NoSidebarSurfaceEffect;

  @override
  int get hashCode => Object.hash(NoSidebarSurfaceEffect, 0);
}

@immutable
class NeumorphSidebarSurfaceEffect extends SidebarSurfaceEffect {
  final Color keyShadowColor;
  final Offset keyShadowOffset;
  final double keyShadowBlur;
  final Color ambientShadowColor;
  final Offset ambientShadowOffset;
  final double ambientShadowBlur;
  final Color borderColor;
  final double borderWidth;

  const NeumorphSidebarSurfaceEffect({
    required this.keyShadowColor,
    required this.keyShadowOffset,
    required this.keyShadowBlur,
    required this.ambientShadowColor,
    required this.ambientShadowOffset,
    required this.ambientShadowBlur,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  SidebarSurfaceEffect lerp(SidebarSurfaceEffect other, double t) {
    if (other is! NeumorphSidebarSurfaceEffect) {
      return super.lerp(other, t);
    }
    return NeumorphSidebarSurfaceEffect(
      keyShadowColor:
          Color.lerp(keyShadowColor, other.keyShadowColor, t) ?? keyShadowColor,
      keyShadowOffset:
          Offset.lerp(keyShadowOffset, other.keyShadowOffset, t) ??
          keyShadowOffset,
      keyShadowBlur:
          lerpDouble(keyShadowBlur, other.keyShadowBlur, t) ?? keyShadowBlur,
      ambientShadowColor:
          Color.lerp(ambientShadowColor, other.ambientShadowColor, t) ??
          ambientShadowColor,
      ambientShadowOffset:
          Offset.lerp(ambientShadowOffset, other.ambientShadowOffset, t) ??
          ambientShadowOffset,
      ambientShadowBlur:
          lerpDouble(ambientShadowBlur, other.ambientShadowBlur, t) ??
          ambientShadowBlur,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t) ?? borderWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeumorphSidebarSurfaceEffect &&
          keyShadowColor == other.keyShadowColor &&
          keyShadowOffset == other.keyShadowOffset &&
          keyShadowBlur == other.keyShadowBlur &&
          ambientShadowColor == other.ambientShadowColor &&
          ambientShadowOffset == other.ambientShadowOffset &&
          ambientShadowBlur == other.ambientShadowBlur &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth;

  @override
  int get hashCode => Object.hash(
    keyShadowColor,
    keyShadowOffset,
    keyShadowBlur,
    ambientShadowColor,
    ambientShadowOffset,
    ambientShadowBlur,
    borderColor,
    borderWidth,
  );
}

sealed class SidebarContentEffect {
  const SidebarContentEffect();

  SidebarContentEffect lerp(SidebarContentEffect other, double t) {
    return t < 0.5 ? this : other;
  }

  List<Shadow>? shadowsFor(Color foreground);
}

@immutable
class NoSidebarContentEffect extends SidebarContentEffect {
  const NoSidebarContentEffect();

  @override
  List<Shadow>? shadowsFor(Color foreground) => null;

  @override
  bool operator ==(Object other) => other is NoSidebarContentEffect;

  @override
  int get hashCode => Object.hash(NoSidebarContentEffect, 0);
}

@immutable
class NeumorphSidebarContentEffect extends SidebarContentEffect {
  final Color keyShadowColor;
  final Offset keyShadowOffset;
  final double keyShadowBlur;
  final double glowOpacity;
  final Offset glowOffset;
  final double glowBlur;

  const NeumorphSidebarContentEffect({
    required this.keyShadowColor,
    required this.keyShadowOffset,
    required this.keyShadowBlur,
    required this.glowOpacity,
    required this.glowOffset,
    required this.glowBlur,
  });

  @override
  SidebarContentEffect lerp(SidebarContentEffect other, double t) {
    if (other is! NeumorphSidebarContentEffect) {
      return super.lerp(other, t);
    }
    return NeumorphSidebarContentEffect(
      keyShadowColor:
          Color.lerp(keyShadowColor, other.keyShadowColor, t) ?? keyShadowColor,
      keyShadowOffset:
          Offset.lerp(keyShadowOffset, other.keyShadowOffset, t) ??
          keyShadowOffset,
      keyShadowBlur:
          lerpDouble(keyShadowBlur, other.keyShadowBlur, t) ?? keyShadowBlur,
      glowOpacity: lerpDouble(glowOpacity, other.glowOpacity, t) ?? glowOpacity,
      glowOffset: Offset.lerp(glowOffset, other.glowOffset, t) ?? glowOffset,
      glowBlur: lerpDouble(glowBlur, other.glowBlur, t) ?? glowBlur,
    );
  }

  @override
  List<Shadow> shadowsFor(Color foreground) {
    return [
      Shadow(
        color: keyShadowColor,
        blurRadius: keyShadowBlur,
        offset: keyShadowOffset,
      ),
      Shadow(
        color: foreground.withValues(alpha: glowOpacity),
        blurRadius: glowBlur,
        offset: glowOffset,
      ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeumorphSidebarContentEffect &&
          keyShadowColor == other.keyShadowColor &&
          keyShadowOffset == other.keyShadowOffset &&
          keyShadowBlur == other.keyShadowBlur &&
          glowOpacity == other.glowOpacity &&
          glowOffset == other.glowOffset &&
          glowBlur == other.glowBlur;

  @override
  int get hashCode => Object.hash(
    keyShadowColor,
    keyShadowOffset,
    keyShadowBlur,
    glowOpacity,
    glowOffset,
    glowBlur,
  );
}
