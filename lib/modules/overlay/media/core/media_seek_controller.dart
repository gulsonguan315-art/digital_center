import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../../../../core/control/device_manager/device_manager.dart';

/// 播放器快进/快退逻辑控制器
/// 负责处理防抖连按、进度计算、虚拟进度（UI展示用）及暂停状态缓存
class MediaSeekController {
  final Player _player;
  final StreamController<String> _interactionStreamController;
  
  final ValueNotifier<Duration?> virtualPositionNotifier = ValueNotifier<Duration?>(null);

  int _lastSeekTime = 0;
  InputSignal? _lastSeekDir;
  
  Duration? _pendingSeekPosition;
  Timer? _seekDebounceTimer;
  bool wasPlayingBeforeSeek = false;

  bool _isDisposed = false;

  MediaSeekController(this._player, this._interactionStreamController);

  void seekRelative(InputSignal dir) {
    if (_isDisposed) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final int deltaMs = now - _lastSeekTime;
    
    // 如果短时间内（<400ms）连续触发同一方向，认为是双击/长按，升级为 30 秒，否则 10 秒
    bool isRapid = (dir == _lastSeekDir) && (deltaMs < 400);
    
    // 防长按高频截流
    if (isRapid && deltaMs < 200 && deltaMs > 0) {
      return; 
    }

    _lastSeekTime = now;
    _lastSeekDir = dir;

    if (_pendingSeekPosition == null) {
      wasPlayingBeforeSeek = _player.state.playing;
      if (wasPlayingBeforeSeek) {
        _player.pause();
      }
    }

    final seconds = isRapid ? 30 : 10;
    final delta = Duration(seconds: dir == InputSignal.left ? -seconds : seconds);
    
    Duration currentPos = _pendingSeekPosition ?? _player.state.position;
    Duration newPosition = currentPos + delta;
    if (newPosition.isNegative) newPosition = Duration.zero;
    if (newPosition > _player.state.duration) newPosition = _player.state.duration;

    _pendingSeekPosition = newPosition;
    virtualPositionNotifier.value = newPosition;
    
    _interactionStreamController.add('${dir == InputSignal.left ? '-' : '+'}${seconds}s');

    _seekDebounceTimer?.cancel();
    _seekDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (_isDisposed) return;
      _executeSeek(newPosition);
    });
  }

  void _executeSeek(Duration newPosition) {
    _player.seek(newPosition);
    if (wasPlayingBeforeSeek) {
      _player.play();
    }
    _pendingSeekPosition = null;
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_isDisposed) return;
      if (_pendingSeekPosition == null) {
        virtualPositionNotifier.value = null;
      }
    });
  }

  void dispose() {
    _isDisposed = true;
    _seekDebounceTimer?.cancel();
    virtualPositionNotifier.dispose();
  }
}
