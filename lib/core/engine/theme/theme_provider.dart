import 'package:flutter/material.dart';
import 'theme_shape.dart';
import 'theme_visuals.dart';

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider instance = ThemeProvider._();
  ThemeProvider._();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  VisualStyle _visualStyle = VisualStyle.neumorphic;
  VisualStyle get visualStyle => _visualStyle;

  ShapeStyle _shapeStyle = ShapeStyle.soft;
  ShapeStyle get shapeStyle => _shapeStyle;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleMode() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void nextVisualStyle() {
    final nextIndex = (_visualStyle.index + 1) % VisualStyle.values.length;
    _visualStyle = VisualStyle.values[nextIndex];
    notifyListeners();
  }

  void setVisualStyle(VisualStyle style) {
    if (_visualStyle == style) return;
    _visualStyle = style;
    notifyListeners();
  }

  void setShapeStyle(ShapeStyle style) {
    if (_shapeStyle == style) return;
    _shapeStyle = style;
    notifyListeners();
  }
}
