import 'package:flutter/foundation.dart';

/// 🔊 全局应用音频服务
///
/// 职责：
/// 1. 维护全局统一的音量状态 (0.0 - 1.0)
/// 2. 供各类播放器（音乐、视频）监听并继承此音量
/// 3. 提供防抖与连按逻辑（单按 1%，连按 5%）
class AppAudioService extends ChangeNotifier {
  static final AppAudioService instance = AppAudioService._();

  double _volume = 0.8;
  double get volume => _volume;

  // 记录上一次改变音量的时间戳，用于连按检测
  int _lastVolumeChangeTime = 0;
  // 连按判定的时间阈值（毫秒）
  static const int _rapidPressThresholdMs = 300;

  AppAudioService._();

  /// 获取本次操作的步进大小（1% 还是 5%）
  double _getStepSize() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final isRapid = (now - _lastVolumeChangeTime) < _rapidPressThresholdMs;
    _lastVolumeChangeTime = now;
    return isRapid ? 0.05 : 0.01;
  }

  /// 提高全局音量
  void volumeUp() {
    final step = _getStepSize();
    _volume = (_volume + step).clamp(0.0, 1.0);
    notifyListeners();
  }

  /// 降低全局音量
  void volumeDown() {
    final step = _getStepSize();
    _volume = (_volume - step).clamp(0.0, 1.0);
    notifyListeners();
  }

  /// 直接设置全局音量
  void setVolume(double val) {
    _volume = val.clamp(0.0, 1.0);
    _lastVolumeChangeTime = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }
}
