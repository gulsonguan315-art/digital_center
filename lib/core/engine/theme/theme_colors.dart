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

  const ThemeColors({
    required this.adormColor,
    required this.surfaceBase,
    required this.surfacePanel,
    required this.surfaceOverlay,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderIdle,
    required this.surfaceBorder,
  });

  factory ThemeColors.light() => const ThemeColors(
    adormColor: Color(0xFF673AB7),
    surfaceBase: Color(0xFFF5F5F7),
    surfacePanel: Color(0xFFFFFFFF),
    surfaceOverlay: Color(0xFFFFFFFF),
    textPrimary: Color(0xDD000000),
    textSecondary: Color(0x8A000000),
    borderIdle: Color(0xFFE0E0E0),
    surfaceBorder: Color(0x1F000000),
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
    );
  }
}
