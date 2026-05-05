import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/control/superfocus/focus_geometry.dart';
import '../../../ui/base/text/surface_text.dart';
import 'sidebar_metrics.dart';

class SidebarTile extends StatelessWidget {
  const SidebarTile({
    super.key,
    required this.id,
    required this.label,
    required this.icon,
    this.isActive = false,
    this.isDisabled = false,
    this.autofocus = false,
    this.onTap,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDisabled;
  final bool autofocus;
  final VoidCallback? onTap;

  Color _resolveForeground(RoleColors colors) {
    if (isDisabled) return colors.textPrimary.withValues(alpha: 0.2);
    if (isActive) return colors.accent;
    return colors.textPrimary.withValues(alpha: 0.7);
  }

  Color _resolveBackground(RoleColors colors, bool isFocused) {
    if (isFocused) return colors.textPrimary.withValues(alpha: 0.08);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
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
        return ThemeIdentity(
          role: ThemeRole.sidebar,
          layer: ThemeLayer.base, 
          child: Builder(
            builder: (context) {
              final material = context.useTheme();
              final colors = material.colors;
              final chrome = material.visual;

              final foreground = _resolveForeground(colors);
              final background = _resolveBackground(colors, isFocused);

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
                      icon,
                      size: 20,
                      color: foreground,
                      // 图标由于不是文本，暂时还不能用 SurfaceText，
                      // 但由于侧边栏 Tile 是 Base 层，我们手动应用 outerShadows
                      shadows: chrome.outerShadows.map((e) => Shadow(
                        color: e.color,
                        offset: e.offset,
                        blurRadius: e.blurRadius,
                      )).toList(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SurfaceText(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: foreground,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
