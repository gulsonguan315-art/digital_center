import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../device_manager.dart';
import 'keyboard_translate.dart';

/// 键盘输入源
///
/// 职责：
/// - 实现 [InputSource] 生命周期（attach / detach）
/// - 将 Widget 树冒泡上来的 [KeyEvent] 交给 [KeyboardTranslate] 翻译
/// - 把翻译结果回调给 [SuperInputManager]
///
/// 注意：本类不直接调用 HardwareKeyboard，
/// 而是通过 [handleKey] 被根节点 Focus.onKeyEvent 被动驱动，
/// 确保 TextField 等原生输入组件优先消费自己的按键事件。
class KeyboardInputSource implements InputSource, KeyEventHandler {
  @override
  String get name => 'Keyboard';

  void Function(InputSignal signal)? _onSignal;

  @override
  void attach(void Function(InputSignal signal) onSignal) {
    _onSignal = onSignal;
  }

  @override
  void detach() {
    _onSignal = null;
  }

  /// 根节点 Focus.onKeyEvent 的嚴饰入口，由 [SuperInputManager.handleRootKeyEvent] 调用。
  @override
  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // 🛡️ 核心安全修复：如果当前焦点在文本输入框（TextField/EditableText）中，禁止全局快捷键拦截退格、回车及方向键，确保原生打字与删除正常
    final primaryFocus = FocusManager.instance.primaryFocus;
    bool isTextInput = false;

    if (primaryFocus != null && primaryFocus.context != null) {
      primaryFocus.context!.visitAncestorElements((element) {
        if (element.widget is EditableText || element.widget is TextField) {
          isTextInput = true;
          return false; // 找到后停止遍历
        }
        return true;
      });
      // 有些情况下本身就是 EditableText
      if (primaryFocus.context!.widget is EditableText ||
          primaryFocus.context!.widget is TextField) {
        isTextInput = true;
      }
    }

    if (isTextInput) {
      if (event.logicalKey == LogicalKeyboardKey.backspace ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        return KeyEventResult.ignored;
      }
    }

    final signal = KeyboardTranslate.translate(event.logicalKey);
    if (signal == null) return KeyEventResult.ignored;
    _onSignal?.call(signal);
    return KeyEventResult.handled;
  }
}
