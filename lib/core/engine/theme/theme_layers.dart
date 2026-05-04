import 'package:flutter/material.dart';

import 'theme_role.dart';
import 'colors/theme_colors.dart';
import 'visuals/theme_visuals.dart';
import 'shapes/theme_shapes.dart';

export 'colors/theme_colors.dart';
export 'visuals/theme_visuals.dart';
export 'shapes/theme_shapes.dart';

@immutable
class ResolvedThemeMaterial {
  const ResolvedThemeMaterial({
    required this.colors,
    required this.visual,
    required this.shape,
  });

  final RoleColors colors;
  final SurfaceEffect visual;
  final RoleShape shape;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResolvedThemeMaterial &&
        other.colors == colors &&
        other.visual == visual &&
        other.shape == shape;
  }

  @override
  int get hashCode => Object.hash(colors, visual, shape);
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
      colors: colors.resolve(role),
      visual: visuals.resolve(role),
      shape: shapes.resolve(role),
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
