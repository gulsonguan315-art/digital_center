import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_geometry.dart';
import '../../../core/control/superfocus/focus_widgets.dart';

import '../../../core/engine/theme/theme_api.dart';
import '../../../core/engine/theme/theme_role.dart';
import '../../visual/surface/themed_surface.dart';

class _OptionItem<T> extends StatelessWidget {
  final String id;
  final String label;
  final bool isSelected;
  final VoidCallback onToggle;

  const _OptionItem({
    required this.id,
    required this.label,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {


    return ThemeIdentity(
      role: ThemeRole.button,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();
          final colors = material.colors;

          return SuperFocusItem(
            id: id,
            onPressed: onToggle,
            focusGeometry: RoundedRectFocusGeometry(
              borderRadius: material.shape.radius as BorderRadius,
            ),
            builder: (context, hasFocus) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: material.shape.radius,
                  color: hasFocus
                      ? colors.textPrimary.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colors.accent
                              : colors.textPrimary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: isSelected ? 1.0 : 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected
                            ? colors.textPrimary
                            : colors.textPrimary.withValues(alpha: 0.7),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SuperFocusSelect<T> extends StatefulWidget {
  final String id;
  final String title;
  final Map<T, String> options;
  final List<T> selectedValues;
  final ValueChanged<T> onToggle;
  final Widget Function(Widget child) roomBuilder;

  const SuperFocusSelect({
    super.key,
    required this.id,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
    required this.roomBuilder,
  });

  @override
  State<SuperFocusSelect<T>> createState() => _SuperFocusSelectState<T>();
}

class _SuperFocusSelectState<T> extends State<SuperFocusSelect<T>> {
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();
          final colors = material.colors;

          return SuperFocusItem(
            id: widget.id,
            onPressed: () {},
            focusGeometry: RoundedRectFocusGeometry(
              borderRadius: material.shape.radius as BorderRadius,
            ),
            builder: (context, isGateFocused) {
              return widget.roomBuilder(
                _buildInternalContent(context, isGateFocused, colors),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInternalContent(
    BuildContext context,
    bool isGateFocused,
    RoleColors colors,
  ) {
    final isRoomActive = RoomScope.of(context)?.isActive ?? false;

    final coreContent = Padding(
      key: _contentKey,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                color: colors.textPrimary.withValues(
                    alpha: isRoomActive ? 0.8 : 0.4,
                  ),
                  letterSpacing: 1.2,
                ),
              ),
              if (isGateFocused)
                Icon(
                  Icons.login_rounded,
                  size: 16,
                  color: colors.accent.withValues(alpha: 0.5),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: widget.options.entries.toList().asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final option = entry.value;
              return _OptionItem<T>(
                id: '${widget.id}_opt_$index',
                label: option.value,
                isSelected: widget.selectedValues.contains(option.key),
                onToggle: () => widget.onToggle(option.key),
              );
            }).toList(),
          ),
        ],
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isRoomActive || isGateFocused ? 1.0 : 0.5,
      child: ThemedSurface(isFocused: isGateFocused, child: coreContent),
    );
  }
}
