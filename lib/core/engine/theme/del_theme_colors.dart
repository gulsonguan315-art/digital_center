import 'package:flutter/material.dart';

/// Legacy ThemeColors stub to keep deprecated UI files compiling.
/// Do not use this for new features. Use context.useTheme() instead.
class ThemeColors extends ThemeExtension<ThemeColors> {
  const ThemeColors({
    this.adormColor = const Color(0xFF64B5F6),
  });

  final Color adormColor;

  @override
  ThemeColors copyWith({Color? adormColor}) {
    return ThemeColors(adormColor: adormColor ?? this.adormColor);
  }

  @override
  ThemeColors lerp(ThemeExtension<ThemeColors>? other, double t) {
    if (other is! ThemeColors) return this;
    return ThemeColors(
      adormColor: Color.lerp(adormColor, other.adormColor, t)!,
    );
  }
}
