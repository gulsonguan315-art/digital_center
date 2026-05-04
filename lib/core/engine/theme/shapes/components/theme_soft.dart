import 'package:flutter/material.dart';
import '../theme_shapes.dart';

final softShapeLayer = ThemeShapeLayer(
  sidebar: RoleShape(radius: BorderRadius.circular(24), concaveRadius: 24),
  card: RoleShape(radius: BorderRadius.circular(24)),
  appBackground: const RoleShape(radius: BorderRadius.zero),
  button: RoleShape(radius: BorderRadius.circular(24)),
);
