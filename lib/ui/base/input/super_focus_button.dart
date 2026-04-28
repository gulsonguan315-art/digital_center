import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/control/superfocus/focus_manager.dart';

/// 标准化按钮组件 - UI 层的极简调用方案
/// 内置了缩放、阴影和背景色切换的视觉反馈。
class SuperFocusButton extends StatelessWidget {
  final String id;
  final String label;
  final VoidCallback? onPressed;
  final bool autofocus;

  const SuperFocusButton({
    super.key,
    required this.id,
    required this.label,
    this.onPressed,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return SuperFocusItem(
      id: id,
      autofocus: autofocus,
      onPressed: onPressed,
      builder: (context, hasFocus) {
        return ValueListenableBuilder<String?>(
          valueListenable: SuperFocusManager.instance.intentionRoomId,
          builder: (context, intentionId, _) {
            final isWaiting = intentionId == id;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              transform: Matrix4.identity()..scale(hasFocus ? 1.1 : 1.0),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: hasFocus
                    ? const Color(0xFF673AB7)
                    : (isWaiting
                          ? Colors.grey.shade300
                          : const Color(0xFFFFFFFF)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: const Color(0xFF673AB7).withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
                border: Border.all(
                  color: hasFocus
                      ? const Color(0x00000000)
                      : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 正常文字
                  Opacity(
                    opacity: isWaiting ? 0.0 : 1.0,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        color: hasFocus
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xDD000000),
                        fontWeight: hasFocus
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Loading 动画
                  if (isWaiting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
