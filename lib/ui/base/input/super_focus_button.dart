import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/control/superfocus/focus_manager.dart';
import '../../../core/engine/theme/theme_colors.dart';
import '../../../core/engine/theme/theme_visuals.dart';
import '../../../core/control/superfocus/focus_geometry.dart';

/// 标准化按钮组件 - UI 层的极简调用方案
/// 内置了缩放、阴影和背景色切换的视觉反馈。
class SuperFocusButton extends StatelessWidget {
  final String id;
  final String label;
  final VoidCallback? onPressed;
  final bool autofocus;

  const SuperFocusButton({
    super.key,
    required this.id,
    required this.label,
    this.onPressed,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;

    return SuperFocusItem(
      id: id,
      autofocus: autofocus,
      onPressed: onPressed,
      focusGeometry: RoundedRectFocusGeometry(
        borderRadius: themeVisuals.defaultRadius as BorderRadius,
      ),
      builder: (context, hasFocus) {
        return ValueListenableBuilder<String?>(
          valueListenable: SuperFocusManager.instance.intentionRoomId,
          builder: (context, intentionId, _) {
            final isWaiting = intentionId == id;

            final themeColors = Theme.of(context).extension<ThemeColors>()!;
            final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;

            return themeVisuals.buttonSurface.apply(
              context,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 正常文字
                    Opacity(
                      opacity: isWaiting ? 0.0 : 1.0,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          color: hasFocus
                              ? themeColors.adormColor
                              : themeColors.textPrimary,
                          fontWeight: hasFocus
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    // Loading 动画
                    if (isWaiting)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            themeColors.adormColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              isFocused: hasFocus,
              isWaiting: isWaiting,
            );
          },
        );
      },
    );
  }
}
