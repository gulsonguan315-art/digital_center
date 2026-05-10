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
    final signal = KeyboardTranslate.translate(event.logicalKey);
    if (signal == null) return KeyEventResult.ignored;
    _onSignal?.call(signal);
    return KeyEventResult.handled;
  }
}
