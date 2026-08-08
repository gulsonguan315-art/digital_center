import 'package:flutter/services.dart';
import '../../device_manager.dart';

/// 系统级媒体键桥接
///
/// 监听底层 C++ 捕获的系统全局按键事件（主要是音量加、音量减），
/// 并将其转换为 [InputSignal] 上报。
class RemoteSystemKeyBridge {
  RemoteSystemKeyBridge._();

  static final RemoteSystemKeyBridge instance = RemoteSystemKeyBridge._();
  static const MethodChannel _channel =
      MethodChannel('gulson/remote_system_keys');

  bool _initialized = false;
  void Function(InputSignal signal)? _onSignal;

  void init(void Function(InputSignal signal) onSignal) {
    if (_initialized) return;
    _initialized = true;
    _onSignal = onSignal;

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'remoteSystemKey') return;

      final raw = call.arguments;
      if (raw is! String) return;

      final signal = switch (raw) {
        'home' => InputSignal.home,
        'volumeUp' => InputSignal.volumeUp,
        'volumeDown' => InputSignal.volumeDown,
        _ => null,
      };

      if (signal != null) {
        _onSignal?.call(signal);
      }
    });
  }
}
