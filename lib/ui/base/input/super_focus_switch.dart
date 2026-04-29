import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/engine/theme/theme_colors.dart';
import '../../../core/engine/theme/theme_visuals.dart';
import '../../../core/control/superfocus/focus_geometry.dart';

/// 标准化开关组件 - 支持超级焦点引擎与动态主题
class SuperFocusSwitch extends StatelessWidget {
  final String id;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final bool autofocus;

  const SuperFocusSwitch({
    super.key,
    required this.id,
    required this.value,
    required this.onChanged,
    this.label,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;

    return SuperFocusItem(
      id: id,
      autofocus: autofocus,
      // 当按下确认键时，触发值的反转
      onPressed: () => onChanged(!value),
      // 焦点游标的几何形状，与组件的圆角保持一致
      focusGeometry: RoundedRectFocusGeometry(
        borderRadius: themeVisuals.defaultRadius as BorderRadius,
      ),
      builder: (context, hasFocus) {
        final themeColors = Theme.of(context).extension<ThemeColors>()!;

        // 焦点状态下，赋予轻微的面板背景色
        final Color bgColor = hasFocus
            ? themeColors.surfacePanel.withValues(
                alpha: themeVisuals.surfaceOpacity,
              )
            : Colors.transparent;

        return ClipRRect(
          borderRadius: themeVisuals.defaultRadius,
          child: BackdropFilter(
            // 如果主题开启了玻璃模糊，应用模糊效果
            filter: ui.ImageFilter.blur(
              sigmaX: hasFocus ? themeVisuals.glassBlur : 0.0,
              sigmaY: hasFocus ? themeVisuals.glassBlur : 0.0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: themeVisuals.defaultRadius,
                border: Border.all(
                  color: hasFocus
                      ? themeColors.adormColor.withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: themeVisuals.borderThickness,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 如果提供了标签文本，则显示文本
                  if (label != null) ...[
                    Text(
                      label!,
                      style: TextStyle(
                        fontSize: 16,
                        color: hasFocus
                            ? themeColors.adormColor
                            : themeColors.textPrimary,
                        fontWeight: hasFocus
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  // 开关的视觉轨道和滑块
                  _buildTrackAndThumb(themeColors, themeVisuals, hasFocus),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建滑动轨道和中心的圆球滑块
  Widget _buildTrackAndThumb(
    ThemeColors colors,
    ThemeVisuals visuals,
    bool hasFocus,
  ) {
    // 轨道颜色：开启时为主题主色，关闭时为闲置边框色
    final trackColor = value
        ? colors.adormColor
        : colors.borderIdle.withValues(alpha: 0.8);

    // 滑块颜色：通常保持白色/深色面板色
    final thumbColor = colors.surfacePanel;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: 48,
      height: 26,
      padding: const EdgeInsets.all(3), // 轨道内边距
      decoration: BoxDecoration(
        color: trackColor,
        // 开关轨道通常使用完全圆角
        borderRadius: BorderRadius.circular(100),
        boxShadow: value && visuals.glassBlur > 0
            ? [
                BoxShadow(
                  color: colors.adormColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        // 根据 value 控制滑块居左还是居右
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: thumbColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
