import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../superfocus/focus_api.dart';
import '../superfocus/interaction_manager.dart';
import '../../engine/audio/app_audio_service.dart';
import '../../log/log_api.dart';
import 'components/keyboard/keyboard_source.dart';
import 'components/remote/remote_source.dart';

import 'components/remote/remote_system_key_bridge.dart';

export 'components/keyboard/keyboard_source.dart';
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

  /// 回到主页
  home,

  /// 呼出控制菜单
  menu,

  /// 音量加
  volumeUp,

  /// 音量减
  volumeDown,
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

/// 具备处理原生 KeyEvent 能力的输入源接口
abstract interface class KeyEventHandler {
  KeyEventResult handleKey(FocusNode node, KeyEvent event);
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. 设备管理中心
//    统一管理所有输入源，接收信号并下发给焦点系统。
//
//    各设备的按键翻译逻辑 → components/*/translate/ (或者直接在子目录下)
//    各设备的驱动实现     → components/*/source/
// ─────────────────────────────────────────────────────────────────────────────

/// 操控设备管理中心（单例）
///
/// 职责：
/// 1. 管理所有物理输入设备（[InputSource]）
/// 2. 接收设备上报的 [InputSignal]
/// 3. 通过 [FocusAPI] 将信号下发给焦点系统
///
/// 扩展新设备只需两步：
/// 1. 在 `components/` 下新建设备文件夹并实现翻译逻辑
/// 2. 在 `components/` 下实现 [InputSource] 并在 [SuperInputManager] 中注册。
class SuperInputManager {
  static final SuperInputManager instance = SuperInputManager._internal();
  SuperInputManager._internal();

  final List<InputSource> _sources = [];
  bool _initialized = false;
  final List<bool Function(InputSignal signal)> _interceptors = [];

  void registerInterceptor(bool Function(InputSignal signal) interceptor) {
    if (!_interceptors.contains(interceptor)) {
      _interceptors.add(interceptor);
    }
  }

  void unregisterInterceptor(bool Function(InputSignal signal) interceptor) {
    _interceptors.remove(interceptor);
  }

  /// 初始化并启动默认输入源（键盘与遥控器）
  void init() {
    if (_initialized) return;
    _initialized = true;
    addSource(KeyboardInputSource());
    addSource(RemoteInputSource());
    
    // 初始化系统全局音量键桥接（解决 Windows 音量键被系统吃掉的问题）
    RemoteSystemKeyBridge.instance.init(_handleSignal);
  }

  /// 挂载一个新的输入设备
  void addSource(InputSource source) {
    _sources.add(source);
    source.attach(_handleSignal);
    Log.d(LogGroup.system, '已接入设备：${source.name}', subGroup: 'DeviceManager');
  }

  /// 卸载一个输入设备
  void removeSource(InputSource source) {
    source.detach();
    _sources.remove(source);
    Log.d(LogGroup.system, '已断开设备：${source.name}', subGroup: 'DeviceManager');
  }

  void _handleSignal(InputSignal signal) {
    Log.d(LogGroup.system, '信号接收：$signal', subGroup: 'DeviceManager');

    // 【全局等待锁】当系统处于关键异步期（如跨界瞬移、页面缩放转场，或网络读数据），
    // 强制拦截除音量控制外的一切用户指令，避免盲操造成焦点暴走或状态混乱。
    if (FocusAPI.isInputLocked) {
      if (signal != InputSignal.volumeUp && signal != InputSignal.volumeDown) {
        Log.d(
          LogGroup.system, 
          '拦截生效：当前为锁定状态，忽略 $signal (原因 -> waiting: ${FocusAPI.isCursorWaiting}, teleporting: ${FocusAPI.isCursorTeleporting}, intention: ${SuperFocusManager.instance.intentionRoomId.value})', 
          subGroup: 'DeviceManager',
        );
        return;
      }
    }

    // 1. 优先遍历拦截器（栈顶优先 LIFO）
    for (final interceptor in _interceptors.reversed) {
      if (interceptor(signal)) { // 如果拦截器返回 true，代表已消费
        Log.d(LogGroup.system, '信号 [$signal] 被拦截器消费', subGroup: 'DeviceManager');
        return; // 立即终止，不触发全局动作
      }
    }

    switch (signal) {
      // 全局独占信号
      case InputSignal.volumeUp:
        AppAudioService.instance.volumeUp();
      case InputSignal.volumeDown:
        AppAudioService.instance.volumeDown();

      // 焦点系统信号
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
      case InputSignal.home:
        FocusAPI.dispatchHomeCommand();
      case InputSignal.menu:
        // menu 信号由局部拦截器消费；若未拦截则在此处忽略
        break;
    }
  }

  /// 根节点 Focus.onKeyEvent 的兜底入口。
  /// 在 main.dart 中挂载，利用 Flutter 事件冒泡：
  /// TextField 等原生输入组件优先消费自己的按键，未消费的才到达这里。
  KeyEventResult handleRootKeyEvent(FocusNode node, KeyEvent event) {
    // 【修复：多 HID 设备路由】遍历所有具备处理 KeyEvent 能力的输入源，直到有人消费
    for (final source in _sources) {
      if (source is KeyEventHandler) {
        final result = (source as KeyEventHandler).handleKey(node, event);
        if (result == KeyEventResult.handled) {
          return KeyEventResult.handled;
        }
      }
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
