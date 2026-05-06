import 'package:flutter/material.dart';

import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../text/surface_text.dart';

/// 焦点化按钮 - 业务层的标准按钮实现
class SuperFocusButton extends StatelessWidget {
  const SuperFocusButton({
    super.key,
    required this.id,
    required this.label,
    this.onPressed,
    this.autofocus = false,
  });

  final String id;
  final String label;
  final VoidCallback? onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    // UI 只认识 API：使用 FocusIdentity 代替 SuperFocusItem
    return FocusIdentity(
      id: id,
      autofocus: autofocus,
      onPressed: onPressed,
      builder: (context, hasFocus) {
        return ThemeIdentity(
          role: ThemeRole.button,
          layer: hasFocus ? ThemeLayer.under : ThemeLayer.base,
          child: Builder(
            builder: (context) {
              final material = context.useTheme();
              final colors = material.colors;

              // 检查是否有意图指向此 ID (用于显示加载状态)
              final bool isWaiting = false;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isWaiting ? colors.accent : colors.surface,
                  borderRadius: material.shape.radius,
                  boxShadow: material.visual.outerShadows,
                  border: Border.all(
                    color: material.visual.borderColor ?? Colors.transparent,
                    width: material.visual.borderWidth,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: isWaiting ? 0.0 : 1.0,
                        child: SurfaceText(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            color: hasFocus
                                ? colors.accent
                                : colors.textPrimary,
                            fontWeight: hasFocus
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      // 使用别名 FocusShape
      focusGeometry: const FocusShape(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}
