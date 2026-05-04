import 'package:flutter/material.dart';

import 'theme_role.dart';

class ThemeIdentity extends InheritedWidget {
  const ThemeIdentity({super.key, required this.role, required super.child});

  final ThemeRole role;

  static ThemeRole? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeIdentity>()?.role;
  }

  static ThemeRole of(BuildContext context) {
    final role = maybeOf(context);
    if (role == null) {
      throw FlutterError.fromParts([
        ErrorSummary('who are you! Missing ThemeIdentity.'),
        ErrorDescription(
          'A widget called useTheme() without declaring one of the legal '
          'ThemeRole identities first.',
        ),
      ]);
    }
    return role;
  }

  @override
  bool updateShouldNotify(ThemeIdentity oldWidget) => role != oldWidget.role;
}
