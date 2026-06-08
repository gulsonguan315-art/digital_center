import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../core/data/data_manager.dart';
import '../../../../core/log/log.dart';
import '../../../resident/media/media_service.dart';
import 'player_engine.dart';

/// 负责维护当前播放剧集的本地偏好设置（倍速、跳过片头片尾开关等）
/// 并负责监控播放进度以自动执行“跳过”与“播完切集”动作。
class MediaPreferencesManager {
  final PlayerEngine playerEngine;
  final VoidCallback onExitRequest;

  String? _currentSeriesId;
  double _playbackSpeed = 1.0;
  bool _autoSkip = false;
  int _introDuration = 0;
  int _outroDuration = 0;

  bool _hasSkippedIntro = false;
  bool _hasSkippedOutro = false;

  StreamSubscription<bool>? _completedSub;
  StreamSubscription<Duration>? _positionSub;

  double get playbackSpeed => _playbackSpeed;
  bool get autoSkip => _autoSkip;
  int get introDuration => _introDuration;
  int get outroDuration => _outroDuration;

  MediaPreferencesManager({
    required this.playerEngine,
    required this.onExitRequest,
  });

  void startListening() {
    _completedSub = playerEngine.player.stream.completed.listen((completed) async {
      if (playerEngine.isSwitchingEpisode) return;
      if (completed) {
        final success = await playerEngine.switchEpisode(1);
        if (!success) {
          onExitRequest();
        }
      }
    });

    _positionSub = playerEngine.player.stream.position.listen((pos) {
      if (playerEngine.isSwitchingEpisode) return;

      if (_autoSkip && _currentSeriesId != null) {
        if (!_hasSkippedIntro &&
            _introDuration > 0 &&
            pos.inMilliseconds < _introDuration) {
          if (pos.inMilliseconds > 1000 &&
              pos.inMilliseconds < _introDuration - 1000) {
            _hasSkippedIntro = true;
            playerEngine.player.seek(
              Duration(milliseconds: _introDuration),
            );
          }
        }
        if (!_hasSkippedOutro && _outroDuration > 0) {
          final total = playerEngine.player.state.duration.inMilliseconds;
          if (total > 0 && pos.inMilliseconds >= total - _outroDuration) {
            _hasSkippedOutro = true;
            Log.d(
              LogGroup.media,
              '⏭️ [Player] 触发跳过片尾，标记已看完: ${playerEngine.currentItemIdNotifier.value}',
            );
            MediaService.instance.markItemAsPlayed(playerEngine.currentItemIdNotifier.value);
            playerEngine.switchEpisode(1);
          }
        }
      }
    });
  }

  Future<void> loadSettingsAndApply() async {
    _hasSkippedIntro = false;
    _hasSkippedOutro = false;

    final details = await MediaService.instance.fetchItemDetails(
      playerEngine.currentItemIdNotifier.value,
    );
    if (details == null) return;
    _currentSeriesId = details['SeriesId'] as String?;
    if (_currentSeriesId != null) {
      final store = DataManager.instance.mediaSettings;
      _playbackSpeed = await store.getSpeed(_currentSeriesId!);
      _autoSkip = await store.getAutoSkip(_currentSeriesId!);
      _introDuration = await store.getIntroDuration(_currentSeriesId!);
      _outroDuration = await store.getOutroDuration(_currentSeriesId!);
    } else {
      _playbackSpeed = 1.0;
      _autoSkip = false;
      _introDuration = 0;
      _outroDuration = 0;
    }
    playerEngine.player.setRate(_playbackSpeed);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    playerEngine.player.setRate(speed);
    if (_currentSeriesId != null) {
      await DataManager.instance.mediaSettings.setSpeed(
        _currentSeriesId!,
        speed,
      );
    }
  }

  Future<void> setAutoSkip(bool autoSkip) async {
    _autoSkip = autoSkip;
    if (_currentSeriesId != null) {
      await DataManager.instance.mediaSettings.setAutoSkip(
        _currentSeriesId!,
        autoSkip,
      );
    }
  }

  Future<void> recordIntro() async {
    _introDuration = playerEngine.player.state.position.inMilliseconds;
    if (_currentSeriesId != null) {
      await DataManager.instance.mediaSettings.setIntroDuration(
        _currentSeriesId!,
        _introDuration,
      );
    }
  }

  Future<void> recordOutro() async {
    final duration = playerEngine.player.state.duration.inMilliseconds;
    final pos = playerEngine.player.state.position.inMilliseconds;
    _outroDuration = duration - pos;
    if (_outroDuration < 0) _outroDuration = 0;
    if (_currentSeriesId != null) {
      await DataManager.instance.mediaSettings.setOutroDuration(
        _currentSeriesId!,
        _outroDuration,
      );
    }
  }

  void dispose() {
    _completedSub?.cancel();
    _positionSub?.cancel();
  }
}
