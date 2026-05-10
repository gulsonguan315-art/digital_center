import '../../device_manager.dart';
import 'gamepad_translate.dart';

/// 手柄输入源（存根）
///
/// 职责：
/// - 实现 [InputSource] 生命周期（attach / detach）
/// - 将手柄事件交给 [GamepadTranslate] 翻译
///
/// 当前状态：骨架已就绪，等待目标平台接入手柄后补充具体的事件监听逻辑。
/// Flutter 的 gamepad 支持依赖平台插件（如 gamepads 包），
/// 接入后在此类中挂载监听，其余架构不需要任何改动。
class GamepadInputSource implements InputSource {
  @override
  String get name => 'Gamepad';

  void Function(InputSignal signal)? _onSignal;

  @override
  void attach(void Function(InputSignal signal) onSignal) {
    _onSignal = onSignal;
    // TODO: 接入平台 Gamepad 插件，在此注册按键监听。
    // 示例（伪代码）：
    // GamepadPlugin.instance.onButtonDown.listen((button) {
    //   final signal = GamepadTranslate.translate(button.logicalKey);
    //   if (signal != null) _onSignal?.call(signal);
    // });
  }

  @override
  void detach() {
    // TODO: 取消平台 Gamepad 插件的监听。
    _onSignal = null;
  }

  /// 手动投喂一个原始按键（供测试或自定义平台通道使用）
  void injectKey(dynamic key) {
    // ignore: unused_local_variable
    final signal = GamepadTranslate.translate(key);
    if (signal != null) _onSignal?.call(signal);
  }
}
