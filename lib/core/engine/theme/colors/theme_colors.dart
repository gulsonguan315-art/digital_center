import 'package:flutter/material.dart';
import '../theme_role.dart';
import 'components/theme_lightcolor.dart';
import 'components/theme_nightcolor.dart';

@immutable
class RoleColors {
  const RoleColors({
    required this.surface,
    required this.foreground,
    required this.foregroundActive,
    required this.foregroundDisabled,
    required this.backgroundFocused,
    required this.backgroundActive,
    required this.border,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color surface;
  final Color foreground;
  final Color foregroundActive;
  final Color foregroundDisabled;
  final Color backgroundFocused;
  final Color backgroundActive;
  final Color border;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
}

@immutable
class ThemeColorLayer extends ThemeExtension<ThemeColorLayer> {
  const ThemeColorLayer({
    required this.sidebar,
    required this.card,
    required this.appBackground,
    required this.button,
  });

  final RoleColors sidebar;
  final RoleColors card;
  final RoleColors appBackground;
  final RoleColors button;

  factory ThemeColorLayer.light() => lightColorLayer;
  factory ThemeColorLayer.dark() => nightColorLayer;

  RoleColors resolve(ThemeRole role) {
    return switch (role) {
      ThemeRole.sidebar => sidebar,
      ThemeRole.card => card,
      ThemeRole.appBackground => appBackground,
      ThemeRole.button => button,
      ThemeRole.defaultRole => card,
    };
  }

  @override
  ThemeColorLayer copyWith({
    RoleColors? sidebar,
    RoleColors? card,
    RoleColors? appBackground,
    RoleColors? button,
  }) {
    return ThemeColorLayer(
      sidebar: sidebar ?? this.sidebar,
      card: card ?? this.card,
      appBackground: appBackground ?? this.appBackground,
      button: button ?? this.button,
    );
  }

  @override
  ThemeColorLayer lerp(ThemeExtension<ThemeColorLayer>? other, double t) {
    if (other is! ThemeColorLayer) return this;
    return ThemeColorLayer(
      sidebar: _lerpRoleColors(sidebar, other.sidebar, t),
      card: _lerpRoleColors(card, other.card, t),
      appBackground: _lerpRoleColors(appBackground, other.appBackground, t),
      button: _lerpRoleColors(button, other.button, t),
    );
  }

  static RoleColors _lerpRoleColors(RoleColors a, RoleColors b, double t) {
    return RoleColors(
      surface: Color.lerp(a.surface, b.surface, t)!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      foregroundActive: Color.lerp(a.foregroundActive, b.foregroundActive, t)!,
      foregroundDisabled: Color.lerp(
        a.foregroundDisabled,
        b.foregroundDisabled,
        t,
      )!,
      backgroundFocused: Color.lerp(
        a.backgroundFocused,
        b.backgroundFocused,
        t,
      )!,
      backgroundActive: Color.lerp(a.backgroundActive, b.backgroundActive, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
    );
  }
}
