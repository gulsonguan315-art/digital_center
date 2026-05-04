import 'package:flutter/material.dart';
import 'theme_layers.dart';

class ThemeFactory {
  /// Unified factory to build ThemeData based on both dimensions
  static ThemeData createTheme(
    Brightness brightness,
    VisualStyle style, [
    ShapeStyle shapeStyle = ShapeStyle.soft,
  ]) {
    final colorLayer = brightness == Brightness.light
        ? ThemeColorLayer.light()
        : ThemeColorLayer.dark();

    final visualLayer = switch (style) {
      VisualStyle.flat => ThemeVisualLayer.flat(),
      VisualStyle.glass => ThemeVisualLayer.glass(),
      VisualStyle.neumorphic => ThemeVisualLayer.neumorphic(),
    };

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

    // Pick a primary color from a prominent role (e.g., button or sidebar accent)
    final primaryColor = colorLayer.sidebar.accent;

    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: colorLayer.appBackground.surface,
      extensions: [
        colorLayer,
        visualLayer,
        shapeLayer,
        appTheme,
      ],
    );
  }

  /// Default themes with chosen presets
  static ThemeData get lightTheme =>
      createTheme(Brightness.light, VisualStyle.flat);
  static ThemeData get darkTheme =>
      createTheme(Brightness.dark, VisualStyle.glass);
}
