import 'package:flutter/material.dart';
import 'theme_colors.dart';
import 'theme_visuals.dart';
import 'visuals/flat_visuals.dart';
import 'visuals/glass_visuals.dart';
import 'visuals/neumorph_visuals.dart';

class ThemeFactory {
  /// Unified factory to build ThemeData based on both dimensions
  static ThemeData createTheme(Brightness brightness, VisualStyle style) {
    final colors = brightness == Brightness.light
        ? ThemeColors.light()
        : ThemeColors.dark();

    final ThemeVisuals visuals;
    switch (style) {
      case VisualStyle.flat:
        visuals = flatVisuals;
        break;
      case VisualStyle.glass:
        visuals = glassVisuals;
        break;
      case VisualStyle.neumorphic:
        visuals = neumorphicVisuals;
        break;
    }

    return ThemeData(
      brightness: brightness,
      primaryColor: colors.adormColor,
      scaffoldBackgroundColor: colors.surfaceBase,
      extensions: [colors, visuals],
    );
  }

  /// Legacy getters updated to use the new factory with defaults
  static ThemeData get lightTheme =>
      createTheme(Brightness.light, VisualStyle.flat);
  static ThemeData get darkTheme =>
      createTheme(Brightness.dark, VisualStyle.glass);
}
