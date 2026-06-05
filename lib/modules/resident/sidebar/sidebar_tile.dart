import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
import '../../../core/control/superfocus/focus_api.dart';
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
    this.isExpandable = false,
    this.isCollapsed = false,
    this.depth = 0,
    this.onTap,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDisabled;
  final bool autofocus;
  final bool isExpandable;
  final bool isCollapsed;
  final int depth;
  final VoidCallback? onTap;

  Color _resolveForeground(RoleColors colors) {
    if (isDisabled) return colors.foregroundDisabled;
    if (isActive) return colors.foregroundActive;
    return colors.foreground;
  }

  Color _resolveBackground(RoleColors colors, bool isFocused) {
    if (isFocused) return colors.backgroundFocused;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return FocusIdentity(
      id: id,
      autofocus: autofocus,
      onPressed: isDisabled ? null : () => onTap?.call(),
      focusGeometry: SidebarTileFocusGeometry(
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(context.units(SidebarMetrics.tileRadiusU)),
          right: isCollapsed 
              ? Radius.zero 
              : Radius.circular(context.units(SidebarMetrics.tileRadiusU)),
        ),
        openRightness: isActive ? 1.0 : 0.0,
        concaveRadius: context.units(SidebarMetrics.surfaceRadiusU),
      ),
      builder: (context, isFocused) {
        // 1. 动态确定层级：只有焦点状态下才升级到 Above 层以获取拟物阴影参数
        final layer = isFocused ? ThemeLayer.above : ThemeLayer.base;

        return ThemeIdentity(
          role: ThemeRole.sidebar,
          layer: layer,
          child: Builder(
            builder: (context) {
              final material = context.useTheme();
              final colors = material.colors;
              final chrome = material.visual;

              final foreground = _resolveForeground(colors);
              final background = _resolveBackground(colors, isFocused);

              // 2. 只有获得焦点且在 Above 层时，才应用阴影
              final List<Shadow>? shadows = isFocused
                  ? chrome.outerShadows
                        .map(
                          (e) => Shadow(
                            color: e.color,
                            offset: e.offset,
                            blurRadius: e.blurRadius,
                          ),
                        )
                        .toList()
                  : null;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: context.units(SidebarMetrics.tileHeightU),
                padding: EdgeInsets.only(
                  left: context.units(isCollapsed ? 0.8 : SidebarMetrics.tilePaddingLeftU),
                  right: context.units(SidebarMetrics.tilePaddingRightU),
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(context.units(SidebarMetrics.tileRadiusU)),
                    right: isCollapsed 
                        ? Radius.zero 
                        : Radius.circular(context.units(SidebarMetrics.tileRadiusU)),
                  ),
                ),
                child: AnimatedScale(
                  scale: (isFocused || isActive) ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: context.units(SidebarMetrics.widthU) - 
                              context.units(SidebarMetrics.contentPaddingLeftU) - 
                              context.units(SidebarMetrics.contentPaddingRightU) - 
                              context.units(SidebarMetrics.tilePaddingLeftU) - 
                              context.units(SidebarMetrics.tilePaddingRightU) - 
                              (isCollapsed ? 0 : depth * context.units(1.6)),
                    maxWidth: context.units(SidebarMetrics.widthU) - 
                              context.units(SidebarMetrics.contentPaddingLeftU) - 
                              context.units(SidebarMetrics.contentPaddingRightU) - 
                              context.units(SidebarMetrics.tilePaddingLeftU) - 
                              context.units(SidebarMetrics.tilePaddingRightU) - 
                              (isCollapsed ? 0 : depth * context.units(1.6)),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: context.units(SidebarMetrics.iconSizeU),
                          color: foreground,
                          shadows: shadows, // 应用拟物阴影
                        ),
                        SizedBox(width: context.units(SidebarMetrics.iconGapU)),
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isCollapsed ? 0.0 : 1.0,
                            child: SurfaceText(
                              label,
                              style: TextStyle(
                                fontSize: context.units(SidebarMetrics.labelSizeU),
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w800,
                                color: foreground,
                                letterSpacing: 0.5,
                                shadows: shadows, // 应用拟物阴影
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isCollapsed ? 0.0 : 1.0,
                          child: Icon(
                            isExpandable
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_right_rounded,
                            size: 14,
                            color: foreground.withValues(alpha: 0.5),
                          ),
                        ),
                        if (isActive) ... [
                          const SizedBox(width: 6),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isCollapsed ? 0.0 : 1.0,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.accent,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
