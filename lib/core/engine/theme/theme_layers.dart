import 'dart:ui';

import 'package:flutter/material.dart';

import 'theme_colors.dart';
import 'theme_role.dart';
import 'theme_shape.dart';
import 'theme_visuals.dart';
import 'visuals/flat_visuals.dart';
import 'visuals/glass_visuals.dart';
import 'visuals/neumorph_visuals.dart';

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

  factory ThemeColorLayer.light() {
    final legacy = ThemeColors.light();
    return ThemeColorLayer.fromLegacy(legacy);
  }

  factory ThemeColorLayer.dark() {
    final legacy = ThemeColors.dark();
    return ThemeColorLayer.fromLegacy(legacy);
  }

  factory ThemeColorLayer.fromLegacy(ThemeColors colors) => ThemeColorLayer(
    sidebar: RoleColors(
      surface: colors.sidebarMain,
      foreground: colors.sidebarForeground,
      foregroundActive: colors.sidebarForegroundActive,
      foregroundDisabled: colors.sidebarForegroundDisabled,
      backgroundFocused: colors.sidebarBackgroundFocused,
      backgroundActive: colors.sidebarBackgroundActive,
      border: colors.surfaceBorder,
      accent: colors.adormColor,
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
    ),
    card: RoleColors(
      surface: colors.surfacePanel,
      foreground: colors.textPrimary,
      foregroundActive: colors.adormColor,
      foregroundDisabled: colors.textSecondary.withValues(alpha: 0.5),
      backgroundFocused: colors.adormColor.withValues(alpha: 0.12),
      backgroundActive: colors.adormColor.withValues(alpha: 0.18),
      border: colors.surfaceBorder,
      accent: colors.adormColor,
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
    ),
    appBackground: RoleColors(
      surface: colors.backgroundCustom,
      foreground: colors.textPrimary,
      foregroundActive: colors.adormColor,
      foregroundDisabled: colors.textSecondary.withValues(alpha: 0.5),
      backgroundFocused: Colors.transparent,
      backgroundActive: Colors.transparent,
      border: colors.borderIdle,
      accent: colors.adormColor,
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
    ),
    button: RoleColors(
      surface: colors.surfacePanel,
      foreground: colors.textPrimary,
      foregroundActive: colors.adormColor,
      foregroundDisabled: colors.textSecondary.withValues(alpha: 0.5),
      backgroundFocused: colors.adormColor.withValues(alpha: 0.12),
      backgroundActive: colors.adormColor.withValues(alpha: 0.18),
      border: colors.surfaceBorder,
      accent: colors.adormColor,
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
    ),
  );

  RoleColors resolve(ThemeRole role) {
    return switch (role) {
      ThemeRole.sidebar => sidebar,
      ThemeRole.card => card,
      ThemeRole.appBackground => appBackground,
      ThemeRole.button => button,
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

  factory ThemeVisualLayer.flat() => ThemeVisualLayer.fromLegacy(flatVisuals);
  factory ThemeVisualLayer.glass() => ThemeVisualLayer.fromLegacy(glassVisuals);
  factory ThemeVisualLayer.neumorphic() =>
      ThemeVisualLayer.fromLegacy(neumorphicVisuals);

  factory ThemeVisualLayer.fromLegacy(ThemeVisuals visuals) => ThemeVisualLayer(
    sidebar: visuals.panelSurface,
    card: visuals.panelSurface,
    appBackground: visuals.panelSurface,
    button: visuals.buttonSurface,
    focusGlowRadius: visuals.focusGlowRadius,
    focusGlowOpacity: visuals.focusGlowOpacity,
  );

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
      focusGlowRadius:
          lerpDouble(focusGlowRadius, other.focusGlowRadius, t) ??
          focusGlowRadius,
      focusGlowOpacity:
          lerpDouble(focusGlowOpacity, other.focusGlowOpacity, t) ??
          focusGlowOpacity,
    );
  }
}

@immutable
class ResolvedThemeMaterial {
  const ResolvedThemeMaterial({
    required this.role,
    required this.colors,
    required this.visual,
    required this.shape,
    required this.focusGlowRadius,
    required this.focusGlowOpacity,
  });

  final ThemeRole role;
  final RoleColors colors;
  final SurfaceEffect visual;
  final RoleShape shape;
  final double focusGlowRadius;
  final double focusGlowOpacity;
}

@immutable
class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme({
    required this.colors,
    required this.visuals,
    required this.shapes,
  });

  final ThemeColorLayer colors;
  final ThemeVisualLayer visuals;
  final ThemeShapeLayer shapes;

  ResolvedThemeMaterial resolve(ThemeRole role) {
    return ResolvedThemeMaterial(
      role: role,
      colors: colors.resolve(role),
      visual: visuals.resolve(role),
      shape: shapes.resolve(role),
      focusGlowRadius: visuals.focusGlowRadius,
      focusGlowOpacity: visuals.focusGlowOpacity,
    );
  }

  @override
  AppTheme copyWith({
    ThemeColorLayer? colors,
    ThemeVisualLayer? visuals,
    ThemeShapeLayer? shapes,
  }) {
    return AppTheme(
      colors: colors ?? this.colors,
      visuals: visuals ?? this.visuals,
      shapes: shapes ?? this.shapes,
    );
  }

  @override
  AppTheme lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this;
    return AppTheme(
      colors: colors.lerp(other.colors, t),
      visuals: visuals.lerp(other.visuals, t),
      shapes: shapes.lerp(other.shapes, t),
    );
  }
}
