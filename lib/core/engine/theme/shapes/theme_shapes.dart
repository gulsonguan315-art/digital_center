import 'package:flutter/material.dart';
import '../theme_role.dart';
import 'components/theme_rightangle.dart';
import 'components/theme_soft.dart';
import 'components/theme_round.dart';

enum ShapeStyle { rightAngle, soft, round }

@immutable
class RoleShape {
  const RoleShape({required this.radius, this.concaveRadius});

  final BorderRadiusGeometry radius;
  final double? concaveRadius;
}

@immutable
class ThemeShapeLayer extends ThemeExtension<ThemeShapeLayer> {
  const ThemeShapeLayer({
    required this.sidebar,
    required this.card,
    required this.appBackground,
    required this.button,
  });

  final RoleShape sidebar;
  final RoleShape card;
  final RoleShape appBackground;
  final RoleShape button;

  factory ThemeShapeLayer.rightAngle() => rightAngleShapeLayer;
  factory ThemeShapeLayer.soft() => softShapeLayer;
  factory ThemeShapeLayer.round() => roundShapeLayer;

  RoleShape resolve(ThemeRole role) {
    return switch (role) {
      ThemeRole.sidebar => sidebar,
      ThemeRole.card => card,
      ThemeRole.appBackground => appBackground,
      ThemeRole.button => button,
    };
  }

  @override
  ThemeShapeLayer copyWith({
    RoleShape? sidebar,
    RoleShape? card,
    RoleShape? appBackground,
    RoleShape? button,
  }) {
    return ThemeShapeLayer(
      sidebar: sidebar ?? this.sidebar,
      card: card ?? this.card,
      appBackground: appBackground ?? this.appBackground,
      button: button ?? this.button,
    );
  }

  @override
  ThemeShapeLayer lerp(ThemeExtension<ThemeShapeLayer>? other, double t) {
    if (other is! ThemeShapeLayer) return this;
    return ThemeShapeLayer(
      sidebar: _lerpRoleShape(sidebar, other.sidebar, t),
      card: _lerpRoleShape(card, other.card, t),
      appBackground: _lerpRoleShape(appBackground, other.appBackground, t),
      button: _lerpRoleShape(button, other.button, t),
    );
  }

  static RoleShape _lerpRoleShape(RoleShape a, RoleShape b, double t) {
    return RoleShape(
      radius: BorderRadiusGeometry.lerp(a.radius, b.radius, t) ?? a.radius,
      concaveRadius: _lerpDouble(a.concaveRadius, b.concaveRadius, t),
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
