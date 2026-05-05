import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';

/// DashboardCard is a universal base panel for dashboard modules.
/// It provides a standardized Neumorphic/Glass surface and sets the
/// ThemeIdentity to [ThemeRole.card].
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.layer = ThemeLayer.base,
    this.fillColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final ThemeLayer layer;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    // 注入身份
    return ThemeIdentity(
      role: ThemeRole.card,
      layer: layer,
      child: Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Builder(
          builder: (context) {
            // 黑盒解析
            final material = context.useTheme();
            final chrome = material.visual;
            final radius = borderRadius ?? material.shape.radius;

            return Container(
              decoration: BoxDecoration(
                color: fillColor ?? material.colors.surface,
                borderRadius: radius,
                boxShadow: chrome.outerShadows,
                border: Border.all(
                  color: chrome.borderColor ?? Colors.transparent,
                  width: chrome.borderWidth,
                ),
              ),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(20.0),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}
