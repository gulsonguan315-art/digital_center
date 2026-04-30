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
    final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;

    return SuperFocusItem(
      id: id,
      autofocus: autofocus,
      onPressed: isDisabled ? null : () => onTap?.call(),
      focusGeometry: SidebarTileFocusGeometry(
        borderRadius: BorderRadius.circular(SidebarMetrics.tileRadius),
        openRightness: isActive ? 1.0 : 0.0,
        concaveRadius: SidebarMetrics.surfaceRadius,
      ),
      builder: (context, isFocused) {
        final foreground = _resolveForeground(themeColors);
        final background = _resolveBackground(themeColors, isFocused);
        final activeShadows = isActive && !isDisabled
            ? themeVisuals.panelSurface.foregroundShadows(
                context: context,
                foregroundColor: foreground,
                isFocused: true,
                fillColor: themeColors.sidebarMain,
              )
            : null;

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
              Icon(
                icon ?? Icons.circle,
                size: SidebarMetrics.iconSize,
                color: foreground,
                shadows: activeShadows,
              ),
              const SizedBox(width: SidebarMetrics.iconGap),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: foreground,
                    fontSize: SidebarMetrics.labelSize,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    shadows: activeShadows,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
