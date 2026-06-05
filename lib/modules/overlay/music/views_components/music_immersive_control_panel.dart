import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';

class MusicImmersiveControlPanel extends StatelessWidget {
  final int currentStyleIndex;
  final ValueChanged<int> onStyleSelect;

  const MusicImmersiveControlPanel({
    super.key,
    required this.currentStyleIndex,
    required this.onStyleSelect,
  });

  Widget _buildItem({
    required BuildContext context,
    required String id,
    required String label,
    required int index,
  }) {
    final isSelected = currentStyleIndex == index;

    return FocusIdentity(
      id: id,
      onPressed: () => onStyleSelect(index),
      builder: (context, hasFocus) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: (isSelected || hasFocus)
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
              fontWeight: (isSelected || hasFocus) ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: SuperFocusRoom(
        id: 'music_menu',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildItem(
              context: context,
              id: 'style_scrolling',
              label: '滚动歌词',
              index: 0,
            ),
            const SizedBox(width: 8),
            _buildItem(
              context: context,
              id: 'style_single_line',
              label: '单行特写',
              index: 1,
            ),
            const SizedBox(width: 8),
            _buildItem(
              context: context,
              id: 'style_mood',
              label: '情绪碎片',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }
}
