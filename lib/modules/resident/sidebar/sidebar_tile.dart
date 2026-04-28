import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_geometry.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/engine/theme/theme_colors.dart';
import '../../../core/engine/theme/theme_visuals.dart';
import 'sidebar_metrics.dart';

class SidebarTile extends StatelessWidget {
  const SidebarTile({
    super.key,
    required this.id,
    required this.label,
    this.icon,
    this.onTap,
    this.isActive = false,
    this.isDisabled = false,
    this.autofocus = false,
  });

  final String id;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isDisabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;
    final sidebarVisual = Theme.of(context).extension<ThemeVisuals>()!.sidebar;

    return SuperFocusItem(
      id: id,
      autofocus: autofocus,
      onPressed: isDisabled ? null : () => onTap?.call(),
      // 侧边栏专属的几何形状：激活项右侧开口，与 Surface 的缺口对接
      focusGeometry: SidebarTileFocusGeometry(
        borderRadius: BorderRadius.circular(SidebarMetrics.tileRadius),
        openRightness: isActive ? 1.0 : 0.0,
        concaveRadius: SidebarMetrics.surfaceRadius,
      ),
      builder: (context, isFocused) {
        final foreground = _resolveForeground(themeColors);
        final background = _resolveBackground(themeColors, isFocused);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: SidebarMetrics.tileHeight,
          padding: const EdgeInsets.only(
            left: SidebarMetrics.tilePaddingLeft,
            right: SidebarMetrics.tilePaddingRight,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(SidebarMetrics.tileRadius),
          ),
          child: Row(
            children: [
              _SidebarIcon(
                icon: icon ?? Icons.circle,
                color: foreground,
                isActive: isActive,
                enabled: !isDisabled,
                visual: sidebarVisual,
              ),
              const SizedBox(width: SidebarMetrics.iconGap),
              Expanded(
                child: _SidebarLabel(
                  label: label,
                  color: foreground,
                  isActive: isActive,
                  enabled: !isDisabled,
                  visual: sidebarVisual,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _resolveForeground(ThemeColors themeColors) {
    if (isDisabled) return themeColors.sidebarForegroundDisabled;
    if (isActive) return themeColors.sidebarForegroundActive;
    return themeColors.sidebarForeground;
  }

  Color _resolveBackground(ThemeColors themeColors, bool isFocused) {
    if (isActive) return Colors.transparent;
    if (isFocused) return themeColors.sidebarBackgroundFocused;
    return Colors.transparent;
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({
    required this.icon,
    required this.color,
    required this.isActive,
    required this.enabled,
    required this.visual,
  });

  final IconData icon;
  final Color color;
  final bool isActive;
  final bool enabled;
  final SidebarVisual visual;

  @override
  Widget build(BuildContext context) {
    if (!isActive || !enabled) {
      return Icon(icon, size: SidebarMetrics.iconSize, color: color);
    }

    return Transform.scale(
      scale: visual.activeScale,
      child: Icon(
        icon,
        size: SidebarMetrics.iconSize,
        color: color,
        shadows: visual.activeContentEffect.shadowsFor(color),
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel({
    required this.label,
    required this.color,
    required this.isActive,
    required this.enabled,
    required this.visual,
  });

  final String label;
  final Color color;
  final bool isActive;
  final bool enabled;
  final SidebarVisual visual;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontSize: SidebarMetrics.labelSize,
      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
      shadows: isActive && enabled
          ? visual.activeContentEffect.shadowsFor(color)
          : null,
    );

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: style,
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
