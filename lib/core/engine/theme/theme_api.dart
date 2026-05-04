import 'package:flutter/material.dart';

import 'theme_identity.dart';
import 'theme_layers.dart';

export 'theme_identity.dart';
export 'theme_layers.dart';

extension UseTheme on BuildContext {
  ResolvedThemeMaterial useTheme() {
    final role = ThemeIdentity.of(this);
    final appTheme = Theme.of(this).extension<AppTheme>();
    if (appTheme == null) {
      throw FlutterError.fromParts([
        ErrorSummary('Missing AppTheme extension.'),
        ErrorDescription(
          'ThemeFactory must install AppTheme before widgets can call '
          'useTheme().',
        ),
      ]);
    }
    return appTheme.resolve(role);
  }
}
