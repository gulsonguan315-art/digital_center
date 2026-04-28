import 'dart:ui' as ui;
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

            // 统一透明度处理：全员玻璃化
            final Color baseSurface = isWaiting
                ? themeColors.borderIdle
                : (hasFocus
                      ? themeColors.adormColor
                      : themeColors.surfacePanel);

            final bgColor = baseSurface.withValues(
              alpha: themeVisuals.surfaceOpacity,
            );

            return ClipRRect(
              borderRadius: themeVisuals.defaultRadius,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: themeVisuals.glassBlur,
                  sigmaY: themeVisuals.glassBlur,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: themeVisuals.defaultRadius,
                    border: Border.all(
                      color: isWaiting
                          ? themeColors.adormColor.withValues(alpha: 0.4)
                          : (hasFocus
                                ? themeColors.adormColor.withValues(alpha: 0.8)
                                : themeColors.surfaceBorder),
                      width: themeVisuals.borderThickness,
                    ),
                    boxShadow: themeVisuals.glassBlur > 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 高光反射层 (仅在玻璃模式下显示)
                      if (themeVisuals.glassBlur > 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: themeVisuals.defaultRadius,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.02),
                                ],
                              ),
                            ),
                          ),
                        ),
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
              ),
            );
          },
        );
      },
    );
  }
}
