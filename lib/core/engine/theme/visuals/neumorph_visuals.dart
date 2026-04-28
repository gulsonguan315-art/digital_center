import 'package:flutter/material.dart';
import '../theme_visuals.dart';

/// 新拟态风格预设 (Neumorphism - 高低浮雕质感)
final neumorphicVisuals = ThemeVisuals(
  glassBlur: 0.0,
  surfaceOpacity: 1.0,
  defaultRadius: BorderRadius.circular(24), // 通常圆角较大
  borderThickness: 0.5,
  focusGlowRadius: 30.0, // 新拟态通常使用广域阴影
  focusGlowOpacity: 0.2,
);
