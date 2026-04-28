import 'package:flutter/material.dart';
import '../theme_visuals.dart';

final neumorphicVisuals = ThemeVisuals(
  glassBlur: 0.0,
  surfaceOpacity: 1.0,
  defaultRadius: BorderRadius.circular(24),
  borderThickness: 0.5,
  focusGlowRadius: 30.0,
  focusGlowOpacity: 0.2,
  sidebar: const SidebarVisual(
    surfaceEffect: NeumorphSidebarSurfaceEffect(
      keyShadowColor: Color.fromARGB(120, 0, 0, 0),
      keyShadowOffset: Offset(6, 6),
      keyShadowBlur: 8.4,
      ambientShadowColor: Color.fromARGB(100, 255, 255, 255),
      ambientShadowOffset: Offset(-6, -6),
      ambientShadowBlur: 6.0,
      borderColor: Color.fromARGB(15, 255, 255, 255),
      borderWidth: 1.0,
    ),
    activeContentEffect: NeumorphSidebarContentEffect(
      keyShadowColor: Color.fromARGB(77, 0, 0, 0),
      keyShadowOffset: Offset(2, 2),
      keyShadowBlur: 6.0,
      glowOpacity: 0.3,
      glowOffset: Offset(1.5, 1.5),
      glowBlur: 4.0,
    ),
    activeScale: 1.08,
  ),
);
