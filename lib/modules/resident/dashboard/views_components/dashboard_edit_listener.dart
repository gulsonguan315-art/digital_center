import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/control/superfocus/focus_manager.dart';
import '../engine/dashboard_controller.dart';
import '../engine/dashboard_models.dart';

class ToggleEditModeIntent extends Intent {
  const ToggleEditModeIntent();
}

/// 🖥️ 看板键盘编辑交互拦截器 (Dashboard Keyboard Edit Listener)
/// 独立管理编辑状态快捷键 (F10/上下文菜单) 以及物理位移与缩放按键交互。
class DashboardEditListener extends StatelessWidget {
  final Widget child;
  final DashboardController controller;

  const DashboardEditListener({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.contextMenu): ToggleEditModeIntent(),
        SingleActivator(LogicalKeyboardKey.f10): ToggleEditModeIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ToggleEditModeIntent: CallbackAction<ToggleEditModeIntent>(
            onInvoke: (_) {
              controller.setEditMode(!controller.isEditMode);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (!controller.isEditMode) return KeyEventResult.ignored;
            if (event is KeyUpEvent) return KeyEventResult.ignored;

            final logicalKey = event.logicalKey;

            // 获取当前聚焦卡片的物理 ID
            final focusedId = SuperFocusManager.instance.state.nodeRegistry.entries
                .where((e) => e.value.node.hasPrimaryFocus)
                .firstOrNull
                ?.key;

            if (focusedId == null) return KeyEventResult.ignored;

            // 1. 如果按下确认键 (Enter / Space)：切换抓取/放置状态
            if (logicalKey == LogicalKeyboardKey.enter ||
                logicalKey == LogicalKeyboardKey.space ||
                logicalKey == LogicalKeyboardKey.select) {
              controller.toggleGrabItem(focusedId);
              return KeyEventResult.handled;
            }

            // 2. 如果当前有任何卡片被“抓取”，则拦截按键输入并执行位移与缩放
            if (controller.grabbedItemId != null) {
              // 极限制守卫：只有被抓取的卡片才能消费按键事件，防止焦点中途飘走
              if (focusedId != controller.grabbedItemId) {
                return KeyEventResult.handled;
              }

              final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
              final itemIndex = controller.items.indexWhere(
                (item) => item.id == focusedId,
              );
              if (itemIndex == -1) return KeyEventResult.handled;
              final item = controller.items[itemIndex];

              if (isShiftPressed) {
                // Shift + 方向键 -> 缩放大小 (spanX, spanY)
                int newSpanX = item.spanX;
                int newSpanY = item.spanY;

                if (logicalKey == LogicalKeyboardKey.arrowLeft) {
                  newSpanX = item.spanX - 1;
                } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
                  newSpanX = item.spanX + 1;
                } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
                  newSpanY = item.spanY - 1;
                } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
                  newSpanY = item.spanY + 1;
                } else {
                  return KeyEventResult.ignored;
                }

                final normalized = DashboardLayoutPolicy.normalize(
                  item.copyWith(spanX: newSpanX, spanY: newSpanY),
                );

                controller.updateItemSpan(focusedId, normalized.spanX, normalized.spanY);
                return KeyEventResult.handled;
              } else {
                // 普通方向键 -> 平移位置 (x, y)
                int newX = item.x;
                int newY = item.y;

                if (logicalKey == LogicalKeyboardKey.arrowLeft) {
                  newX = item.x - 1;
                } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
                  newX = item.x + 1;
                } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
                  newY = item.y - 1;
                } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
                  newY = item.y + 1;
                } else {
                  return KeyEventResult.ignored;
                }

                final normalized = DashboardLayoutPolicy.normalize(
                  item.copyWith(x: newX, y: newY),
                );

                controller.updateItemPosition(focusedId, normalized.x, normalized.y);
                return KeyEventResult.handled;
              }
            }

            return KeyEventResult.ignored;
          },
          child: child,
        ),
      ),
    );
  }
}
