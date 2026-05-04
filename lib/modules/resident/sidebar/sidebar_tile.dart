import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_geometry.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
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
    final material = context.useTheme();

    return SuperFocusItem(
      id: id,
      autofocus: autofocus,
      onPressed: isDisabled ? null : () => onTap?.call(),
      focusGeometry: SidebarTileFocusGeometry(
        borderRadius: BorderRadius.circular(
          context.units(SidebarMetrics.tileRadiusU),
        ),
        openRightness: isActive ? 1.0 : 0.0,
        concaveRadius: context.units(SidebarMetrics.surfaceRadiusU),
      ),
      builder: (context, isFocused) {
        final foreground = _resolveForeground(material.colors);
        final background = _resolveBackground(material.colors, isFocused);
        final activeShadows = isActive && !isDisabled
            ? material.visual.foregroundShadows(
                foregroundColor: foreground,
                isFocused: true,
                fillColor: material.colors.surface,
              )
            : null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: context.units(SidebarMetrics.tileHeightU),
          padding: EdgeInsets.only(
            left: context.units(SidebarMetrics.tilePaddingLeftU),
            right: context.units(SidebarMetrics.tilePaddingRightU),
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(
              context.units(SidebarMetrics.tileRadiusU),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon ?? Icons.circle,
                size: context.units(SidebarMetrics.iconSizeU),
                color: foreground,
                shadows: activeShadows,
              ),
              SizedBox(width: context.units(SidebarMetrics.iconGapU)),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: foreground,
                    fontSize: context.units(SidebarMetrics.labelSizeU),
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

  Color _resolveForeground(RoleColors colors) {
    if (isDisabled) return colors.foregroundDisabled;
    if (isActive) return colors.foregroundActive;
    return colors.foreground;
  }

  Color _resolveBackground(RoleColors colors, bool isFocused) {
    if (isActive) return Colors.transparent;
    if (isFocused) return colors.backgroundFocused;
    return Colors.transparent;
  }
}
