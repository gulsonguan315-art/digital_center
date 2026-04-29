import 'package:flutter/material.dart';

@immutable
class ThemeColors extends ThemeExtension<ThemeColors> {
  final Color adormColor;
  final Color surfaceBase;
  final Color surfacePanel;
  final Color surfaceOverlay;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderIdle;
  final Color surfaceBorder;
  final Color silk;
  final Color backgroundCustom;
  final Color sidebarMain;
  final Color sidebarForeground;
  final Color sidebarForegroundActive;
  final Color sidebarForegroundDisabled;
  final Color sidebarForegroundSibling;
  final Color sidebarForegroundOutsideBranch;
  final Color sidebarBackgroundFocused;
  final Color sidebarBackgroundActive;
  final Color sidebarBackgroundAncestor;
  final Color sidebarBackgroundSibling;
  final Color sidebarBackgroundOutsideBranch;

  const ThemeColors({
    required this.adormColor,
    required this.surfaceBase,
    required this.surfacePanel,
    required this.surfaceOverlay,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderIdle,
    required this.surfaceBorder,
    required this.silk,
    required this.backgroundCustom,
    required this.sidebarMain,
    required this.sidebarForeground,
    required this.sidebarForegroundActive,
    required this.sidebarForegroundDisabled,
    required this.sidebarForegroundSibling,
    required this.sidebarForegroundOutsideBranch,
    required this.sidebarBackgroundFocused,
    required this.sidebarBackgroundActive,
    required this.sidebarBackgroundAncestor,
    required this.sidebarBackgroundSibling,
    required this.sidebarBackgroundOutsideBranch,
  });

  factory ThemeColors.light() => const ThemeColors(
    adormColor: Color(0xFF673AB7),
    surfaceBase: Color(0xFFD3D3D3),
    surfacePanel: Color(0xFFFFFFFF),
    surfaceOverlay: Color(0xFFFFFFFF),
    textPrimary: Color(0xDD000000),
    textSecondary: Color(0x8A000000),
    borderIdle: Color(0xFFE0E0E0),
    surfaceBorder: Color(0x1F000000),
    silk: Colors.black,
    backgroundCustom: Color(0xFFD3D3D3),
    sidebarMain: Color(0xFF778899),
    sidebarForeground: Color(0xE0121826),
    sidebarForegroundActive: Color(0xFF673AB7),
    sidebarForegroundDisabled: Color(0x66121826),
    sidebarForegroundSibling: Color(0xB0121826),
    sidebarForegroundOutsideBranch: Color(0x80121826),
    sidebarBackgroundFocused: Color(0x14673AB7),
    sidebarBackgroundActive: Color(0x1F673AB7),
    sidebarBackgroundAncestor: Color(0x10673AB7),
    sidebarBackgroundSibling: Color(0x0A121826),
    sidebarBackgroundOutsideBranch: Color(0x05121826),
  );

  factory ThemeColors.dark() => const ThemeColors(
    adormColor: Color(0xFFFF9800),
    surfaceBase: Color(0xFF121212),
    surfacePanel: Color(0xFF1E1E1E),
    surfaceOverlay: Color(0xFF2C2C2C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
    borderIdle: Color(0xFF333333),
    surfaceBorder: Color(0x33FFFFFF),
    silk: Color.fromARGB(94, 255, 255, 255),
    backgroundCustom: Color.fromARGB(95, 0, 0, 0),
    sidebarMain: Color(0xFF1E1E1E),
    sidebarForeground: Color(0xB3FFFFFF),
    sidebarForegroundActive: Color(0xFFFF9800),
    sidebarForegroundDisabled: Color(0x4DFFFFFF),
    sidebarForegroundSibling: Color(0x80FFFFFF),
    sidebarForegroundOutsideBranch: Color(0x66FFFFFF),
    sidebarBackgroundFocused: Color(0x14FF9800),
    sidebarBackgroundActive: Color(0x1FFF9800),
    sidebarBackgroundAncestor: Color(0x10FF9800),
    sidebarBackgroundSibling: Color(0x0AFFFFFF),
    sidebarBackgroundOutsideBranch: Color(0x05FFFFFF),
  );

  @override
  ThemeColors copyWith({
    Color? adormColor,
    Color? surfaceBase,
    Color? surfacePanel,
    Color? surfaceOverlay,
    Color? textPrimary,
    Color? textSecondary,
    Color? borderIdle,
    Color? surfaceBorder,
    Color? silk,
    Color? backgroundCustom,
    Color? sidebarMain,
    Color? sidebarForeground,
    Color? sidebarForegroundActive,
    Color? sidebarForegroundDisabled,
    Color? sidebarForegroundSibling,
    Color? sidebarForegroundOutsideBranch,
    Color? sidebarBackgroundFocused,
    Color? sidebarBackgroundActive,
    Color? sidebarBackgroundAncestor,
    Color? sidebarBackgroundSibling,
    Color? sidebarBackgroundOutsideBranch,
  }) {
    return ThemeColors(
      adormColor: adormColor ?? this.adormColor,
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfacePanel: surfacePanel ?? this.surfacePanel,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      borderIdle: borderIdle ?? this.borderIdle,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      silk: silk ?? this.silk,
      backgroundCustom: backgroundCustom ?? this.backgroundCustom,
      sidebarMain: sidebarMain ?? this.sidebarMain,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      sidebarForegroundActive:
          sidebarForegroundActive ?? this.sidebarForegroundActive,
      sidebarForegroundDisabled:
          sidebarForegroundDisabled ?? this.sidebarForegroundDisabled,
      sidebarForegroundSibling:
          sidebarForegroundSibling ?? this.sidebarForegroundSibling,
      sidebarForegroundOutsideBranch:
          sidebarForegroundOutsideBranch ?? this.sidebarForegroundOutsideBranch,
      sidebarBackgroundFocused:
          sidebarBackgroundFocused ?? this.sidebarBackgroundFocused,
      sidebarBackgroundActive:
          sidebarBackgroundActive ?? this.sidebarBackgroundActive,
      sidebarBackgroundAncestor:
          sidebarBackgroundAncestor ?? this.sidebarBackgroundAncestor,
      sidebarBackgroundSibling:
          sidebarBackgroundSibling ?? this.sidebarBackgroundSibling,
      sidebarBackgroundOutsideBranch:
          sidebarBackgroundOutsideBranch ?? this.sidebarBackgroundOutsideBranch,
    );
  }

  @override
  ThemeColors lerp(ThemeExtension<ThemeColors>? other, double t) {
    if (other is! ThemeColors) {
      return this;
    }
    return ThemeColors(
      adormColor: Color.lerp(adormColor, other.adormColor, t)!,
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfacePanel: Color.lerp(surfacePanel, other.surfacePanel, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      borderIdle: Color.lerp(borderIdle, other.borderIdle, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      silk: Color.lerp(silk, other.silk, t)!,
      backgroundCustom: Color.lerp(
        backgroundCustom,
        other.backgroundCustom,
        t,
      )!,
      sidebarMain: Color.lerp(sidebarMain, other.sidebarMain, t)!,
      sidebarForeground: Color.lerp(
        sidebarForeground,
        other.sidebarForeground,
        t,
      )!,
      sidebarForegroundActive: Color.lerp(
        sidebarForegroundActive,
        other.sidebarForegroundActive,
        t,
      )!,
      sidebarForegroundDisabled: Color.lerp(
        sidebarForegroundDisabled,
        other.sidebarForegroundDisabled,
        t,
      )!,
      sidebarForegroundSibling: Color.lerp(
        sidebarForegroundSibling,
        other.sidebarForegroundSibling,
        t,
      )!,
      sidebarForegroundOutsideBranch: Color.lerp(
        sidebarForegroundOutsideBranch,
        other.sidebarForegroundOutsideBranch,
        t,
      )!,
      sidebarBackgroundFocused: Color.lerp(
        sidebarBackgroundFocused,
        other.sidebarBackgroundFocused,
        t,
      )!,
      sidebarBackgroundActive: Color.lerp(
        sidebarBackgroundActive,
        other.sidebarBackgroundActive,
        t,
      )!,
      sidebarBackgroundAncestor: Color.lerp(
        sidebarBackgroundAncestor,
        other.sidebarBackgroundAncestor,
        t,
      )!,
      sidebarBackgroundSibling: Color.lerp(
        sidebarBackgroundSibling,
        other.sidebarBackgroundSibling,
        t,
      )!,
      sidebarBackgroundOutsideBranch: Color.lerp(
        sidebarBackgroundOutsideBranch,
        other.sidebarBackgroundOutsideBranch,
        t,
      )!,
    );
  }
}
