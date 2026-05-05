import 'package:flutter/material.dart';

import 'theme_identity.dart';
import 'theme_layers.dart';

export 'theme_identity.dart';
export 'theme_layers.dart';
export 'theme_role.dart';

extension UseTheme on BuildContext {
  /// 绝对黑盒：内部根据身份和层级自动产出渲染结果。
  ResolvedThemeMaterial useTheme() {
    // 1. 自动寻找当前上下文的身份证
    final identity = ThemeIdentity.of(this);

    // 2. 获取主题配置
    final appTheme = Theme.of(this).extension<AppTheme>();
    if (appTheme == null) {
      throw FlutterError.fromParts([
        ErrorSummary('Missing AppTheme extension.'),
      ]);
    }

    // 3. 内部自动解析：我是谁(role)，我在哪(layer)
    return appTheme.resolve(
      identity.role,
      layer: identity.layer,
    );
  }
}
