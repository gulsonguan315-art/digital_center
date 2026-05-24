import 'package:flutter/material.dart';
import '../theme_colors.dart';

const lightColorLayer = ThemeColorLayer(
  sidebar: RoleColors(
    surface: Color(0xFFFF6347),
    foreground: Color(0xFFFFFFFF),
    foregroundActive: Color(0xFF673AB7),
    foregroundDisabled: Color(0xFF121826),
    backgroundFocused: Color(0x00673AB7),
    backgroundActive: Color(0xFF673AB7),
    border: Color(0xFFFFFFFF),
    accent: Color(0xFF673AB7),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF000000),
    textActive: Color(0xFF673AB7), // 新增
    textFocused: Color(0xFFFFFFFF), // 新增
  ),
  card: RoleColors(
    surface: Color(0xFFD3D3D3),
    foreground: Color(0x33000000),
    foregroundActive: Color(0xFF673AB7),
    foregroundDisabled: Color(0x00000000),
    backgroundFocused: Color(0x1F673AB7),
    backgroundActive: Color(0x2E673AB7),
    border: Color(0xFFFFFFFF),
    accent: Color(0xFFD2691E),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0x99000000),
    textActive: Color(0xFF673AB7), // 新增
    textFocused: Color(0xFF000000), // 新增
  ),
  appBackground: RoleColors(
    surface: Color(0xFFD3D3D3),
    foreground: Color(0xFF000000),
    foregroundActive: Color(0xFF673AB7),
    foregroundDisabled: Color(0x80000000),
    backgroundFocused: Colors.transparent,
    backgroundActive: Colors.transparent,
    border: Color(0xFFE0E0E0),
    accent: Color(0xFF673AB7),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF000000),
    textActive: Color(0xFF673AB7), // 新增
    textFocused: Color(0xFF673AB7), // 新增
  ),
  button: RoleColors(
    surface: Color(0xFF2F4F4F),
    foreground: Color(0xFF000000),
    foregroundActive: Color(0xFF673AB7),
    foregroundDisabled: Color(0x80000000),
    backgroundFocused: Color(0x1F673AB7),
    backgroundActive: Color(0x2E673AB7),
    border: Color(0xFFFFFFFF),
    accent: Color(0xFF673AB7),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF000000),
    textActive: Color(0xFF673AB7), // 新增
    textFocused: Color(0xFF673AB7), // 新增
  ),
);
