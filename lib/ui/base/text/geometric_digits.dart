import 'package:flutter/material.dart';

/// 几何数字路径生成器 - 工业级块状版本 (5x7 网格思路)
class GeometricDigits {
  static const double _t = 0.2; // 统一笔画厚度

  static Path getPath(int digit) {
    switch (digit) {
      case 0: return _getPath0();
      case 1: return _getPath1();
      case 2: return _getPath2();
      case 3: return _getPath3();
      case 4: return _getPath4();
      case 5: return _getPath5();
      case 6: return _getPath6();
      case 7: return _getPath7();
      case 8: return _getPath8();
      case 9: return _getPath9();
      default: return Path();
    }
  }

  static Path _getPath0() {
    return Path()
      ..addRect(const Rect.fromLTWH(0, 0, 0.8, 1.0))
      ..addRect(const Rect.fromLTWH(_t, _t, 0.8 - 2 * _t, 1.0 - 2 * _t))
      ..fillType = PathFillType.evenOdd;
  }

  static Path _getPath1() {
    return Path()..addRect(const Rect.fromLTWH(0.6 - _t, 0, _t, 1.0));
  }

  static Path _getPath2() {
    final p = Path();
    p.addRect(const Rect.fromLTWH(0, 0, 0.8, _t)); // Top
    p.addRect(const Rect.fromLTWH(0.8 - _t, 0, _t, 0.5)); // Right Top
    p.addRect(const Rect.fromLTWH(0, 0.5 - _t/2, 0.8, _t)); // Mid
    p.addRect(const Rect.fromLTWH(0, 0.5, _t, 0.5)); // Left Bot
    p.addRect(const Rect.fromLTWH(0, 1.0 - _t, 0.8, _t)); // Bot
    return p;
  }

  static Path _getPath3() {
    final p = Path();
    p.addRect(const Rect.fromLTWH(0, 0, 0.8, _t)); // Top
    p.addRect(const Rect.fromLTWH(0.8 - _t, 0, _t, 1.0)); // Right
    p.addRect(const Rect.fromLTWH(0, 0.5 - _t/2, 0.8, _t)); // Mid
    p.addRect(const Rect.fromLTWH(0, 1.0 - _t, 0.8, _t)); // Bot
    return p;
  }

  static Path _getPath4() {
    final p = Path();
    p.addRect(const Rect.fromLTWH(0, 0, _t, 0.5)); // Left Top
    p.addRect(const Rect.fromLTWH(0.8 - _t, 0, _t, 1.0)); // Right
    p.addRect(const Rect.fromLTWH(0, 0.5 - _t/2, 0.8, _t)); // Mid
    return p;
  }

  static Path _getPath5() {
    final p = Path();
    p.addRect(const Rect.fromLTWH(0, 0, 0.8, _t)); // Top
    p.addRect(const Rect.fromLTWH(0, 0, _t, 0.5)); // Left Top
    p.addRect(const Rect.fromLTWH(0, 0.5 - _t/2, 0.8, _t)); // Mid
    p.addRect(const Rect.fromLTWH(0.8 - _t, 0.5, _t, 0.5)); // Right Bot
    p.addRect(const Rect.fromLTWH(0, 1.0 - _t, 0.8, _t)); // Bot
    return p;
  }

  static Path _getPath6() {
    final p = Path();
    p.addRect(const Rect.fromLTWH(0, 0, 0.8, _t)); // Top
    p.addRect(const Rect.fromLTWH(0, 0, _t, 1.0)); // Left
    p.addRect(const Rect.fromLTWH(0, 0.5 - _t/2, 0.8, _t)); // Mid
    p.addRect(const Rect.fromLTWH(0.8 - _t, 0.5, _t, 0.5)); // Right Bot
    p.addRect(const Rect.fromLTWH(0, 1.0 - _t, 0.8, _t)); // Bot
    return p;
  }

  static Path _getPath7() {
    final p = Path();
    p.addRect(const Rect.fromLTWH(0, 0, 0.8, _t)); // Top
    p.addRect(const Rect.fromLTWH(0.8 - _t, 0, _t, 1.0)); // Right
    return p;
  }

  static Path _getPath8() {
    final p = Path();
    p.addRect(const Rect.fromLTWH(0, 0, 0.8, 1.0)); // Outer
    p.addRect(const Rect.fromLTWH(_t, _t, 0.8 - 2 * _t, 0.5 - 1.5 * _t)); // Inner Top
    p.addRect(const Rect.fromLTWH(_t, 0.5 + _t/2, 0.8 - 2 * _t, 0.5 - 1.5 * _t)); // Inner Bot
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  static Path _getPath9() {
    final p = Path();
    p.addRect(const Rect.fromLTWH(0, 0, 0.8, _t)); // Top
    p.addRect(const Rect.fromLTWH(0, 0, _t, 0.5)); // Left Top
    p.addRect(const Rect.fromLTWH(0.8 - _t, 0, _t, 1.0)); // Right
    p.addRect(const Rect.fromLTWH(0, 0.5 - _t/2, 0.8, _t)); // Mid
    p.addRect(const Rect.fromLTWH(0, 1.0 - _t, 0.8, _t)); // Bot
    return p;
  }

  static Path getColonPath() {
    return Path()
      ..addRect(const Rect.fromLTWH(0.3, 0.25, _t, _t))
      ..addRect(const Rect.fromLTWH(0.3, 0.65, _t, _t));
  }
}
