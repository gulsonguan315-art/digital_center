import 'package:flutter/material.dart';

/// Legacy ThemeVisuals stub to keep deprecated UI files compiling.
/// Do not use this for new features. Use context.useTheme() instead.
class ThemeVisuals extends ThemeExtension<ThemeVisuals> {
  const ThemeVisuals({
    this.defaultRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final BorderRadius defaultRadius;

  @override
  ThemeVisuals copyWith({BorderRadius? defaultRadius}) {
    return ThemeVisuals(defaultRadius: defaultRadius ?? this.defaultRadius);
  }

  @override
  ThemeVisuals lerp(ThemeExtension<ThemeVisuals>? other, double t) {
    if (other is! ThemeVisuals) return this;
    return ThemeVisuals(
      defaultRadius: BorderRadius.lerp(defaultRadius, other.defaultRadius, t)!,
    );
  }
}
