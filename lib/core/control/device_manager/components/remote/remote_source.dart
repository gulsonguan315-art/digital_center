import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../device_manager.dart';
import 'remote_translate.dart';

/// 遥控器输入源（存根）
///
/// 职责：
/// - 实现 [InputSource] 生命周期（attach / detach）
/// - 将遥控器按键事件交给 [RemoteTranslate] 翻译
///
/// 遥控器的接入方式有两种：
/// 1. **键盘事件冒泡**（大多数遥控器走 HID，像键盘一样上报）：
///    直接复用 [KeyboardInputSource] 的 handleKey，或在此类中新增方法。
/// 2. **专用平台通道**（如 AndroidTV 遥控器插件）：
///    在 attach 中注册平台通道监听，事件回调后交给 [RemoteTranslate]。
///
/// 当前默认方案：走事件冒泡，通过 [handleKey] 被动驱动（与键盘同路）。
class RemoteInputSource implements InputSource {
  @override
  String get name => 'Remote';

  void Function(InputSignal signal)? _onSignal;

  @override
  void attach(void Function(InputSignal signal) onSignal) {
    _onSignal = onSignal;
    // TODO: 如果遥控器走专用平台通道，在此注册监听。
    // 示例（伪代码）：
    // RemotePlugin.instance.onKeyDown.listen((key) {
    //   final signal = RemoteTranslate.translate(key);
    //   if (signal != null) _onSignal?.call(signal);
    // });
  }

  @override
  void detach() {
    // TODO: 取消平台通道监听。
    _onSignal = null;
  }

  /// 根节点 Focus.onKeyEvent 的嚴饰入口（适用于走 HID/键盘事件的遥控器）。
  /// 由 [SuperInputManager.handleRootKeyEvent] 调用。
  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final signal = RemoteTranslate.translate(event.logicalKey);
    if (signal == null) return KeyEventResult.ignored;
    _onSignal?.call(signal);
    return KeyEventResult.handled;
  }
}
