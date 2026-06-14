import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/control/device_manager/device_manager.dart';
import '../../../../core/log/log.dart';

import 'media_input_handler.dart';
import 'media_preferences_manager.dart';
import 'media_target_resolver.dart';
import 'player_engine.dart';

enum PlaybackPhase {
  preparing,
  fetchingHistory,
  parsingFirstEpisode,
  buildingEngine,
  playing,
}

/// 沉浸式播放器顶级控制器，接管了引擎、进度条、交互流以及输入事件的响应
class MediaImmersiveController {
  final VoidCallback onExitRequest;

  bool _isDisposed = false;

  final StreamController<String> interactionStreamController =
      StreamController<String>.broadcast();
  late final PlayerEngine playerEngine;
  late final MediaInputHandler inputHandler;
  late final MediaPreferencesManager preferencesManager;

  ValueNotifier<String> get currentItemIdNotifier => playerEngine.currentItemIdNotifier;
  
  final ValueNotifier<PlaybackPhase> playbackPhase = ValueNotifier(PlaybackPhase.preparing);

  MediaImmersiveController({
    required String sourceItemId,
    String? mediaType,
    required this.onExitRequest,
    int startPositionTicks = 0,
    bool forceStartOver = false,
  }) {
    // Call async resolution and initialization
    _resolveAndPlay(
      sourceItemId,
      mediaType,
      startPositionTicks,
      forceStartOver,
    );
  }

  /// 在导航返回 **之前** 调用，await 完成后 Jellyfin 已收到正确进度。
  /// 主要用于切集等需要可靠性的内部流程。
  Future<void> stopAndReport() async {
    if (playbackPhase.value.index >= PlaybackPhase.buildingEngine.index) {
      await playerEngine.reporter.stopAndReport();
    }
  }

  /// 触发最终播放进度上报（后台异步，不阻塞）。
  /// UI 层退出时应使用此方法，让用户感觉立即返回详情页。
  void stopAndReportAsync() {
    if (playbackPhase.value.index >= PlaybackPhase.buildingEngine.index) {
      playerEngine.reporter.stopAndReportAsync();
    }
  }

  void dispose() {
    _isDisposed = true;
    if (playbackPhase.value.index >= PlaybackPhase.buildingEngine.index) {
      playerEngine.dispose();
      preferencesManager.dispose();
    }

    interactionStreamController.close();
    playbackPhase.dispose();
  }

  /// 输入信号局部拦截与处理（委托给瞎子 handler）
  bool handleLocalInput(InputSignal signal) {
    return inputHandler.handleLocalInput(signal);
  }

  Future<void> _waitForHeaderForSeek() async {
    if (playerEngine.player.state.duration > Duration.zero) return;
    final completer = Completer<void>();
    late StreamSubscription sub;
    sub = playerEngine.player.stream.duration.listen((dur) {
      if (dur > Duration.zero) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });
    return completer.future;
  }

  Future<void> _resolveAndPlay(
    String sourceId,
    String? mediaType,
    int passedTicks,
    bool forceStartOver,
  ) async {
    playbackPhase.value = PlaybackPhase.preparing;

    final target = await MediaTargetResolver.resolve(
      sourceId: sourceId,
      mediaType: mediaType,
      passedTicks: passedTicks,
      forceStartOver: forceStartOver,
      onPhaseChanged: (phase) => playbackPhase.value = phase,
    );

    String targetId = target.id;
    int targetTicks = target.ticks;

    playbackPhase.value = PlaybackPhase.buildingEngine;

    playerEngine = PlayerEngine(
      initialItemId: targetId,
      interactionStreamController: interactionStreamController,
    );

    preferencesManager = MediaPreferencesManager(
      playerEngine: playerEngine,
      onExitRequest: onExitRequest,
    );

    playerEngine.onEpisodeSwitched = preferencesManager.loadSettingsAndApply;

    inputHandler = MediaInputHandler(
      playerEngine: playerEngine,
    );

    playerEngine.init(startPositionTicks: targetTicks);

    preferencesManager.startListening();
    preferencesManager.loadSettingsAndApply();

    if (targetTicks > 0) {
      final seekDuration = Duration(microseconds: targetTicks ~/ 10);
      Log.d(
        LogGroup.media,
        '⏩ [Player] 续播 seek: startPositionTicks=$targetTicks → ${seekDuration.inSeconds}s',
      );
      await _waitForHeaderForSeek();
      await playerEngine.player.seek(seekDuration);
    } else {
      Log.d(LogGroup.media, '▶️ [Player] 从头播放 (startPositionTicks=0)');
    }

    if (!_isDisposed) {
      playbackPhase.value = PlaybackPhase.playing;
    }
  }
}
