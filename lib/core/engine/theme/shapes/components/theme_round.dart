import 'package:flutter/material.dart';
import '../theme_shapes.dart';

final roundShapeLayer = ThemeShapeLayer(
  sidebar: RoleShape(radius: BorderRadius.circular(32), concaveRadius: 32),
  card: RoleShape(radius: BorderRadius.circular(32)),
  appBackground: const RoleShape(radius: BorderRadius.zero),
  button: RoleShape(radius: BorderRadius.circular(999)),
);
