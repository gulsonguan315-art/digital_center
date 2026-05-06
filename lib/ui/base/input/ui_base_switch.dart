import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/engine/theme/theme_api.dart';

/// 选项数据模型
class SelectOption<T> {
  final T value;
  final String label;
  final String id;
  const SelectOption({required this.value, required this.label, required this.id});
}

/// 标准超焦点开关
class SuperFocusSwitch extends StatelessWidget {
  const SuperFocusSwitch({
    super.key,
    required this.id,
    required this.value,
    required this.onChanged,
    this.label,
    this.autofocus = false,
  });

  final String id;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool autofocus;

  bool get _enabled => onChanged != null;

  void _toggle() {
    if (!_enabled) return;
    onChanged!(!value);
  }

  @override
  Widget build(BuildContext context) {
    return FocusIdentity(
      id: id,
      autofocus: autofocus,
      onPressed: _enabled ? _toggle : null,
      focusGeometry: const RoundedRectFocusGeometry(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      builder: (context, hasFocus) {
        final material = context.useTheme();
        final colors = material.colors;
        final chrome = material.visual;

        final switchControl = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 58,
          height: 34,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: value
                ? colors.accent.withValues(alpha: _enabled ? 1.0 : 0.35)
                : colors.surface,
            boxShadow: hasFocus || value ? chrome.outerShadows : null,
            border: Border.all(
              color: hasFocus ? colors.accent : (chrome.borderColor ?? colors.border),
              width: hasFocus ? 2.0 : chrome.borderWidth,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? colors.surface : colors.textPrimary,
                boxShadow: chrome.outerShadows,
              ),
            ),
          ),
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            switchControl,
            if (label != null) ...[
              const SizedBox(width: 12),
              Text(
                label!,
                style: TextStyle(
                  color: colors.textPrimary.withValues(alpha: _enabled ? 1.0 : 0.4),
                  fontSize: 16,
                  fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 选项项组件
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
    return FocusIdentity(
      id: id,
      onPressed: onToggle,
      focusGeometry: const RoundedRectFocusGeometry(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      builder: (context, hasFocus) {
        final material = context.useTheme();
        final colors = material.colors;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: material.shape.radius,
            color: hasFocus 
                ? colors.textPrimary.withValues(alpha: 0.1) 
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.accent : colors.textPrimary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected ? colors.textPrimary : colors.textPrimary.withValues(alpha: 0.6),
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

/// 超焦点选择器
class SuperFocusSelect<T> extends StatelessWidget {
  final String id;
  final String title;
  final List<SelectOption<T>> options;
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
  Widget build(BuildContext context) {
    return FocusIdentity(
      id: id,
      focusGeometry: const RoundedRectFocusGeometry(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      builder: (context, isFocused) {
        return ThemeIdentity(
          role: ThemeRole.card,
          child: Builder(
            builder: (context) {
              final material = context.useTheme();
              return roomBuilder(
                _buildCardFrame(context, isFocused, material),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCardFrame(BuildContext context, bool isFocused, ResolvedThemeMaterial material) {
    final colors = material.colors;
    final chrome = material.visual;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: material.shape.radius,
        boxShadow: chrome.outerShadows,
        border: Border.all(
          color: chrome.borderColor ?? Colors.transparent,
          width: chrome.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary.withValues(alpha: 0.8),
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((option) {
                return _OptionItem<T>(
                  id: option.id, // 使用传入的物理 ID
                  label: option.label,
                  isSelected: selectedValues.contains(option.value),
                  onToggle: () => onToggle(option.value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
