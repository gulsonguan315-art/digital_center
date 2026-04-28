import 'package:flutter/material.dart';
import '../theme_visuals.dart';

final grassVisuals = ThemeVisuals(
  glassBlur: 0.0,
  surfaceOpacity: 1.0,
  defaultRadius: BorderRadius.circular(16),
  borderThickness: 1.0,
  focusGlowRadius: 12.0,
  focusGlowOpacity: 0.25,
  sidebar: const SidebarVisual(
    surfaceEffect: NoSidebarSurfaceEffect(),
    activeContentEffect: NoSidebarContentEffect(),
    activeScale: 1.0,
  ),
);
