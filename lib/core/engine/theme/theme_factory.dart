import 'package:flutter/material.dart';
import 'theme_colors.dart';
import 'theme_layers.dart';
import 'theme_shape.dart';
import 'theme_visuals.dart';
import 'visuals/flat_visuals.dart';
import 'visuals/glass_visuals.dart';
import 'visuals/neumorph_visuals.dart';

class ThemeFactory {
  /// Unified factory to build ThemeData based on both dimensions
  static ThemeData createTheme(
    Brightness brightness,
    VisualStyle style, [
    ShapeStyle shapeStyle = ShapeStyle.soft,
  ]) {
    final colors = brightness == Brightness.light
        ? ThemeColors.light()
        : ThemeColors.dark();
    final colorLayer = brightness == Brightness.light
        ? ThemeColorLayer.light()
        : ThemeColorLayer.dark();

    final ThemeVisuals visuals;
    final ThemeVisualLayer visualLayer;
    switch (style) {
      case VisualStyle.flat:
        visuals = flatVisuals;
        visualLayer = ThemeVisualLayer.flat();
        break;
      case VisualStyle.glass:
        visuals = glassVisuals;
        visualLayer = ThemeVisualLayer.glass();
        break;
      case VisualStyle.neumorphic:
        visuals = neumorphicVisuals;
        visualLayer = ThemeVisualLayer.neumorphic();
        break;
    }

    final shapeLayer = switch (shapeStyle) {
      ShapeStyle.rightAngle => ThemeShapeLayer.rightAngle(),
      ShapeStyle.soft => ThemeShapeLayer.soft(),
      ShapeStyle.round => ThemeShapeLayer.round(),
    };
    final appTheme = AppTheme(
      colors: colorLayer,
      visuals: visualLayer,
      shapes: shapeLayer,
    );

    return ThemeData(
      brightness: brightness,
      primaryColor: colors.adormColor,
      scaffoldBackgroundColor: colors.surfaceBase,
      extensions: [
        colors,
        visuals,
        colorLayer,
        visualLayer,
        shapeLayer,
        appTheme,
      ],
    );
  }

  /// Legacy getters updated to use the new factory with defaults
  static ThemeData get lightTheme =>
      createTheme(Brightness.light, VisualStyle.flat);
  static ThemeData get darkTheme =>
      createTheme(Brightness.dark, VisualStyle.glass);
}
