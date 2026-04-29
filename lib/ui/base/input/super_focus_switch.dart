import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/engine/theme/theme_colors.dart';
import '../../../core/engine/theme/theme_visuals.dart';

/// 选项原子项 - 属于子房间
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
    final themeColors = Theme.of(context).extension<ThemeColors>()!;

    return SuperFocusItem(
      id: id,
      onPressed: onToggle,
      builder: (context, hasFocus) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            // 选项获得焦点时可以有微弱背景
            color: hasFocus
                ? themeColors.textPrimary.withOpacity(0.05)
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
                        ? themeColors.adormColor
                        : themeColors.textPrimary.withOpacity(0.2),
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
                      color: themeColors.adormColor,
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
                      ? themeColors.textPrimary
                      : themeColors.textPrimary.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 区域级选择器 - 组件即房间 (Component as Room)
/// 区域级选择器 - 组件即房间 (Component as Room)
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
  // 神奇的 GlobalKey，用来在 UI 包装结构剧变时，保住内部选项与 FocusNode 的命
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;
    final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;

    // 1. 最外层是大门，它注册在父房间中（不受 apply 结构变化的影响）
    return SuperFocusItem(
      id: widget.id,
      onPressed: () {},
      builder: (context, isGateFocused) {
        // 2. 大门内部，开启子房间作用域
        return widget.roomBuilder(
          _buildInternalContent(
            context,
            isGateFocused,
            themeColors,
            themeVisuals,
          ),
        );
      },
    );
  }

  Widget _buildInternalContent(
    BuildContext context,
    bool isGateFocused,
    ThemeColors themeColors,
    ThemeVisuals themeVisuals,
  ) {
    final bool isRoomActive = RoomScope.of(context)?.isActive ?? false;

    // 将核心内容单独抽出来，并挂上 GlobalKey
    final coreContent = Padding(
      key: _contentKey, // 👈 护身符在这里
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
                  color: themeColors.textPrimary.withValues(
                    alpha: isRoomActive ? 0.8 : 0.4,
                  ),
                  letterSpacing: 1.2,
                ),
              ),
              if (isGateFocused)
                Icon(
                  Icons.login_rounded,
                  size: 16,
                  color: themeColors.adormColor.withValues(alpha: 0.5),
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
                id: "${widget.id}_opt_$index",
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
      child: themeVisuals.buttonSurface.apply(
        context,
        coreContent, // 将挂有护身符的 content 丢进加工机
        isFocused: isGateFocused,
      ),
    );
  }
}
