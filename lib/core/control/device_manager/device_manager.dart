import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../superfocus/focus_api.dart';
import 'components/keyboard/keyboard_source.dart';
export 'components/gamepad/gamepad_source.dart';
export 'components/remote/remote_source.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. 原子信号枚举
//    所有物理设备的输入，最终都被翻译为这 6 种原子信号。
//    焦点系统只认识这 6 种信号，对物理设备一无所知。
// ─────────────────────────────────────────────────────────────────────────────

/// 设备管理模块输出的原子输入信号
enum InputSignal {
  /// 向上移动焦点
  up,

  /// 向下移动焦点
  down,

  /// 向左移动焦点
  left,

  /// 向右移动焦点
  right,

  /// 确认/选择当前焦点项
  confirm,

  /// 返回/取消
  back,
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. 输入源抽象
//    所有物理设备驱动都实现此接口。
// ─────────────────────────────────────────────────────────────────────────────

/// 物理输入设备的抽象基类
abstract class InputSource {
  /// 设备名称（用于调试日志）
  String get name;

  /// 启动设备监听，将翻译后的信号通过 [onSignal] 回调上报
  void attach(void Function(InputSignal signal) onSignal);

  /// 停止设备监听，释放资源
  void detach();
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. 设备管理中心
//    统一管理所有输入源，接收信号并下发给焦点系统。
//
//    各设备的按键翻译逻辑 → translate/
//    各设备的驱动实现     → sources/
// ─────────────────────────────────────────────────────────────────────────────

/// 操控设备管理中心（单例）
///
/// 职责：
/// 1. 管理所有物理输入设备（[InputSource]）
/// 2. 接收设备上报的 [InputSignal]
/// 3. 通过 [FocusAPI] 将信号下发给焦点系统
///
/// 扩展新设备只需两步：
/// 1. 在 `translate/` 下新建翻译表（如 `remote_translate.dart`）
/// 2. 在 `sources/`   下新建输入源（如 `remote_source.dart`）
/// 然后 `SuperInputManager.instance.addSource(RemoteInputSource())` 即可。
class SuperInputManager {
  static final SuperInputManager instance = SuperInputManager._internal();
  SuperInputManager._internal();

  final List<InputSource> _sources = [];
  bool _initialized = false;

  /// 初始化并启动默认输入源（键盘）
  void init() {
    if (_initialized) return;
    _initialized = true;
    addSource(KeyboardInputSource());
  }

  /// 挂载一个新的输入设备
  void addSource(InputSource source) {
    _sources.add(source);
    source.attach(_handleSignal);
    assert(() {
      print('[DeviceManager] 已接入设备：${source.name}');
      return true;
    }());
  }

  /// 卸载一个输入设备
  void removeSource(InputSource source) {
    source.detach();
    _sources.remove(source);
    assert(() {
      print('[DeviceManager] 已断开设备：${source.name}');
      return true;
    }());
  }

  /// 接收来自任意输入源的 [InputSignal]，下发给焦点系统
  void _handleSignal(InputSignal signal) {
    assert(() {
      print('[DeviceManager] 信号接收：$signal');
      return true;
    }());

    switch (signal) {
      case InputSignal.up:
        FocusAPI.dispatchMove(TraversalDirection.up);
      case InputSignal.down:
        FocusAPI.dispatchMove(TraversalDirection.down);
      case InputSignal.left:
        FocusAPI.dispatchMove(TraversalDirection.left);
      case InputSignal.right:
        FocusAPI.dispatchMove(TraversalDirection.right);
      case InputSignal.confirm:
        FocusAPI.dispatchConfirm();
      case InputSignal.back:
        FocusAPI.dispatchBackCommand();
    }
  }

  /// 根节点 Focus.onKeyEvent 的嚴饰入口。
  /// 在 main.dart 中挂载，利用 Flutter 事件冒泡：
  /// TextField 等原生输入组件优先消费自己的按键，未消费的才到达这里。
  KeyEventResult handleRootKeyEvent(FocusNode node, KeyEvent event) {
    final keyboardSource = _sources
        .whereType<KeyboardInputSource>()
        .firstOrNull;
    if (keyboardSource != null) {
      return keyboardSource.handleKey(node, event);
    }
    return KeyEventResult.ignored;
  }

  /// 销毁所有输入源，释放资源
  void dispose() {
    for (final source in _sources) {
      source.detach();
    }
    _sources.clear();
    _initialized = false;
  }
}
