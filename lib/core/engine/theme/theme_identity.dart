import 'package:flutter/material.dart';

import 'theme_role.dart';

class ThemeIdentity extends InheritedWidget {
  const ThemeIdentity({
    super.key,
    required this.role,
    this.layer = ThemeLayer.base,
    required super.child,
  });

  final ThemeRole role;
  final ThemeLayer layer;

  static ThemeIdentity? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeIdentity>();
  }

  static ThemeIdentity of(BuildContext context) {
    final identity = maybeOf(context);
    if (identity == null) {
      throw FlutterError.fromParts([
        ErrorSummary('who are you! Missing ThemeIdentity.'),
        ErrorDescription(
          'A widget called useTheme() without declaring one of the legal '
          'ThemeRole identities first.',
        ),
      ]);
    }
    return identity;
  }

  @override
  bool updateShouldNotify(ThemeIdentity oldWidget) =>
      role != oldWidget.role || layer != oldWidget.layer;
}
