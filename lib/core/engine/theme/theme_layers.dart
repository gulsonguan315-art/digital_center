import 'package:flutter/material.dart';

import 'colors/theme_colors.dart';
import 'shapes/theme_shapes.dart';
import 'theme_role.dart';
import 'visuals/theme_visuals.dart';

export 'colors/theme_colors.dart';
export 'shapes/theme_shapes.dart';
export 'visuals/theme_visuals.dart';

@immutable
class ResolvedThemeMaterial {
  const ResolvedThemeMaterial({
    required this.colors,
    required this.visual,
    required this.shape,
    required this.focusGlowRadius,
    required this.focusGlowOpacity,
  });

  final RoleColors colors;
  final SurfaceChrome visual;
  final RoleShape shape;
  final double focusGlowRadius;
  final double focusGlowOpacity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResolvedThemeMaterial &&
        other.colors == colors &&
        other.visual == visual &&
        other.shape == shape &&
        other.focusGlowRadius == focusGlowRadius &&
        other.focusGlowOpacity == focusGlowOpacity;
  }

  @override
  int get hashCode =>
      Object.hash(colors, visual, shape, focusGlowRadius, focusGlowOpacity);
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

  ResolvedThemeMaterial resolve(
    ThemeRole role, {
    ThemeLayer layer = ThemeLayer.base,
  }) {
    final roleColors = colors.resolve(role);

    return ResolvedThemeMaterial(
      colors: roleColors,
      visual: visuals.resolve(
        role,
        accent: roleColors.accent,
        border: roleColors.border,
        surface: roleColors.surface,
        layer: layer,
      ),
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
