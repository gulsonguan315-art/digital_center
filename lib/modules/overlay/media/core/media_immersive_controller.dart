import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/control/superfocus/interaction_manager.dart';
import '../../../../core/control/device_manager/device_manager.dart';
import '../../../../core/data/data_manager.dart';
import '../../../../core/log/log.dart';
import '../../../resident/media/media_service.dart';

import 'media_engine_controller.dart';
import 'media_seek_controller.dart';

/// 沉浸式播放器顶级控制器，接管了引擎、进度条、交互流以及输入事件的响应
class MediaImmersiveController {
  final VoidCallback onExitRequest;
  
  final StreamController<String> interactionStreamController = StreamController<String>.broadcast();
  late final MediaEngineController engineController;
  late final MediaSeekController seekController;
  
  late final ValueNotifier<String> currentItemIdNotifier;
  late StreamSubscription<bool> _completedSub;
  late StreamSubscription<Duration> _positionSub;

  /// 用于续播 seek 的 duration 监听（等待媒体加载就绪后 seek），dispose 时清理
  StreamSubscription<Duration>? _resumeReadySubscription;

  // 加载和退出状态，用于慢网络下的动态提示
  final ValueNotifier<bool> isPlayerReady = ValueNotifier(false);
  final ValueNotifier<String> loadingMessage = ValueNotifier('正在初始化播放器...');

  final ValueNotifier<bool> isExiting = ValueNotifier(false);
  final ValueNotifier<String> exitingMessage = ValueNotifier('');

  String? currentSeriesId;
  double _playbackSpeed = 1.0;
  bool _autoSkip = false;
  int _introDuration = 0;
  int _outroDuration = 0;
  bool _isSwitchingEpisode = false;
  bool _stopReported = false;
  
  bool _hasSkippedIntro = false;
  bool _hasSkippedOutro = false;

  double get playbackSpeed => _playbackSpeed;
  bool get autoSkip => _autoSkip;
  int get introDuration => _introDuration;
  int get outroDuration => _outroDuration;

  MediaImmersiveController({
    required String initialItemId,
    required this.onExitRequest,
    int startPositionTicks = 0,
  }) {
    currentItemIdNotifier = ValueNotifier<String>(initialItemId);
    engineController = MediaEngineController(
      interactionStreamController: interactionStreamController,
    );

    loadingMessage.value = '正在初始化播放器...';
    engineController.init(initialItemId, startPositionTicks: startPositionTicks);

    if (startPositionTicks > 0) {
      loadingMessage.value = '正在准备续播位置...';
      _seekToResumePosition(startPositionTicks);
    } else {
      Log.d(LogGroup.media, '▶️ [Player] 从头播放 (startPositionTicks=0)');
      _setupInitialReadyListener();
    }

    seekController = MediaSeekController(
      engineController.player,
      interactionStreamController,
    );

    _completedSub = engineController.player.stream.completed.listen((completed) async {
      if (_isSwitchingEpisode) return;
      if (completed) {
        final success = await switchEpisode(1);
        if (!success) {
          onExitRequest();
        }
      }
    });

    _positionSub = engineController.player.stream.position.listen((pos) {
      if (_isSwitchingEpisode) return;
      
      if (_autoSkip && currentSeriesId != null) {
        if (!_hasSkippedIntro && _introDuration > 0 && pos.inMilliseconds < _introDuration) {
          if (pos.inMilliseconds > 1000 && pos.inMilliseconds < _introDuration - 1000) {
            _hasSkippedIntro = true;
            engineController.player.seek(Duration(milliseconds: _introDuration));
          }
        }
        if (!_hasSkippedOutro && _outroDuration > 0) {
          final total = engineController.player.state.duration.inMilliseconds;
          if (total > 0 && pos.inMilliseconds >= total - _outroDuration) {
            _hasSkippedOutro = true;
            Log.d(LogGroup.media, '⏭️ [Player] 触发跳过片尾，标记已看完: ${currentItemIdNotifier.value}');
            MediaService.instance.markItemAsPlayed(currentItemIdNotifier.value);
            switchEpisode(1);
          }
        }
      }
    });

    _loadSettingsAndApply();
  }

  Future<void> _loadSettingsAndApply() async {
    _hasSkippedIntro = false;
    _hasSkippedOutro = false;

    final details = await MediaService.instance.fetchItemDetails(currentItemIdNotifier.value);
    if (details == null) return;
    currentSeriesId = details['SeriesId'] as String?;
    if (currentSeriesId != null) {
      final store = DataManager.instance.mediaSettings;
      _playbackSpeed = await store.getSpeed(currentSeriesId!);
      _autoSkip = await store.getAutoSkip(currentSeriesId!);
      _introDuration = await store.getIntroDuration(currentSeriesId!);
      _outroDuration = await store.getOutroDuration(currentSeriesId!);
    } else {
      _playbackSpeed = 1.0;
      _autoSkip = false;
      _introDuration = 0;
      _outroDuration = 0;
    }
    engineController.player.setRate(_playbackSpeed);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    engineController.player.setRate(speed);
    if (currentSeriesId != null) {
      await DataManager.instance.mediaSettings.setSpeed(currentSeriesId!, speed);
    }
  }

  Future<void> setAutoSkip(bool autoSkip) async {
    _autoSkip = autoSkip;
    if (currentSeriesId != null) {
      await DataManager.instance.mediaSettings.setAutoSkip(currentSeriesId!, autoSkip);
    }
  }

  Future<void> recordIntro() async {
    _introDuration = engineController.player.state.position.inMilliseconds;
    if (currentSeriesId != null) {
      await DataManager.instance.mediaSettings.setIntroDuration(currentSeriesId!, _introDuration);
    }
  }

  Future<void> recordOutro() async {
    final duration = engineController.player.state.duration.inMilliseconds;
    final pos = engineController.player.state.position.inMilliseconds;
    _outroDuration = duration - pos;
    if (_outroDuration < 0) _outroDuration = 0;
    if (currentSeriesId != null) {
      await DataManager.instance.mediaSettings.setOutroDuration(currentSeriesId!, _outroDuration);
    }
  }

  /// 在导航返回 **之前** 调用，await 完成后 Jellyfin 已收到正确进度
  Future<void> stopAndReport() async {
    if (_stopReported) return;
    _stopReported = true;

    // 立即停止心跳定时器，防止 Stopped 之后还有多余的 Progress 上报
    engineController.cancelProgressTimer();

    final itemId = currentItemIdNotifier.value;
    final finalTicks = engineController.player.state.position.inMicroseconds * 10;
    Log.d(LogGroup.media, '🛑 [Player] stopAndReport: itemId=$itemId, ticks=${finalTicks ~/ 10000000}s');
    await MediaService.instance.reportPlaybackProgress(
      itemId,
      finalTicks,
      action: 'Playing/Stopped',
      playSessionId: engineController.playSessionId,
    );
  }

  void dispose() {
    // 正常情况下 stopAndReport 已在导航前被 await，这里只是保险
    if (!_stopReported) {
      final itemId = currentItemIdNotifier.value;
      final finalTicks = engineController.player.state.position.inMicroseconds * 10;
      Log.d(LogGroup.media, '⚠️ [Player] dispose fallback report: ticks=${finalTicks ~/ 10000000}s');
      MediaService.instance.reportPlaybackProgress(
        itemId,
        finalTicks,
        action: 'Playing/Stopped',
        playSessionId: engineController.playSessionId,
      );
    }
    _resumeReadySubscription?.cancel();
    _positionSub.cancel();
    _completedSub.cancel();
    seekController.dispose();
    engineController.dispose();
    interactionStreamController.close();
    currentItemIdNotifier.dispose();
  }

  /// 剧集切换逻辑（1 = 下一集, -1 = 上一集）
  Future<bool> switchEpisode(int direction) async {
    if (_isSwitchingEpisode || currentSeriesId == null) return false;
    
    // Stop reporting for the current episode
    final stoppedItemId = currentItemIdNotifier.value;
    final stoppedTicks = engineController.player.state.position.inMicroseconds * 10;
    Log.d(LogGroup.media, '🛑 [Player] 切集上报 Playing/Stopped: itemId=$stoppedItemId, ticks=$stoppedTicks (${stoppedTicks ~/ 10000000}s)');
    await MediaService.instance.reportPlaybackProgress(
      stoppedItemId,
      stoppedTicks,
      action: 'Playing/Stopped',
      playSessionId: engineController.playSessionId,
    );

    _isSwitchingEpisode = true;
    
    try {
      final details = await MediaService.instance.fetchItemDetails(currentItemIdNotifier.value);
      if (details == null) return false;
      
      // 如果不是剧集，则属于“不支持切集”的类型，一律报错误提醒
      if (details['Type'] != 'Episode') {
        interactionStreamController.add(direction > 0 ? 'error_next_episode' : 'error_prev_episode');
        return false;
      }
      
      final seriesId = details['SeriesId'] as String?;
      final seasonId = details['SeasonId'] as String?;
      if (seriesId == null || seasonId == null) {
        interactionStreamController.add(direction > 0 ? 'error_next_episode' : 'error_prev_episode');
        return false;
      }
      
      final episodes = await MediaService.instance.fetchEpisodes(seriesId, seasonId);
      final currentIndex = episodes.indexWhere((ep) => ep['Id'] == currentItemIdNotifier.value);
      if (currentIndex == -1) {
        interactionStreamController.add(direction > 0 ? 'error_next_episode' : 'error_prev_episode');
        return false;
      }
      
      final targetIndex = currentIndex + direction;
      if (targetIndex >= 0 && targetIndex < episodes.length) {
        final nextId = episodes[targetIndex]['Id'] as String?;
        if (nextId != null) {
          currentItemIdNotifier.value = nextId;
          engineController.playItem(nextId);
          interactionStreamController.add(direction > 0 ? 'next_episode' : 'prev_episode');
          await _loadSettingsAndApply(); // Re-apply rate and settings for new item
          return true;
        }
      }
      
      // 到了第一集再按上一集，或者最后一集再按下一集（暂不跨季切）
      interactionStreamController.add(direction > 0 ? 'error_next_episode' : 'error_prev_episode');
      return false;
    } finally {
      _isSwitchingEpisode = false;
    }
  }

  /// 输入信号局部拦截与处理
  bool handleLocalInput(InputSignal signal) {
    final showMenu = SuperFocusManager.instance.state.checkIsActive('media_menu');
    final showHomeConfirm = SuperFocusManager.instance.state.checkIsActive('media_home_confirm');

    if (showMenu || showHomeConfirm) {
      if (signal == InputSignal.menu || signal == InputSignal.back) {
        FocusAPI.dispatchBackCommand();
        if (showHomeConfirm &&
            !engineController.player.state.playing &&
            seekController.wasPlayingBeforeSeek) {
          engineController.player.play(); // 如果弹窗取消，恢复播放
        }
        return true;
      }
      return false; // 允许菜单项/弹窗内正常使用方向键与确认键
    } else {
      switch (signal) {
        case InputSignal.menu:
          // 动作触发焦点从空气节点路由转移至菜单 media_menu
          FocusAPI.dispatchAction('media_overlay', 'media_overlay_air_node');
          return true;
        case InputSignal.confirm:
          // Enter/确认键 暂停或播放
          engineController.player.playOrPause();
          return true;
        case InputSignal.left:
          // 左键快退 10 秒 / 长按 30 秒
          seekController.seekRelative(InputSignal.left);
          return true;
        case InputSignal.right:
          // 右键快进 10 秒 / 长按 30 秒
          seekController.seekRelative(InputSignal.right);
          return true;
        case InputSignal.home:
          // 暂停播放，并触发拓扑跳转，显示自定义的焦点弹窗
          seekController.wasPlayingBeforeSeek = engineController.player.state.playing;
          if (seekController.wasPlayingBeforeSeek) {
            engineController.player.pause();
          }
          FocusAPI.dispatchAction('media_overlay', 'media_home_trigger');
          return true;
        case InputSignal.up:
          switchEpisode(-1);
          return true;
        case InputSignal.down:
          switchEpisode(1);
          return true;
        case InputSignal.volumeUp:
        case InputSignal.volumeDown:
        case InputSignal.back:
          return false; // 放行给全局处理（回退或调整全局音量）
      }
    }
  }

  /// 等待播放器就绪（duration 已知）后再执行续播 seek，避免魔法数字延迟。
  /// 使用 player.stream.duration 事件驱动，确保媒体信息加载完成（可安全 seek）后再 seek。
  /// 同时处理已就绪的竞态情况。
  void _seekToResumePosition(int ticks) {
    final seekDuration = Duration(microseconds: ticks ~/ 10);
    Log.d(LogGroup.media, '⏩ [Player] 续播 seek: startPositionTicks=$ticks → ${seekDuration.inSeconds}s');

    // 如果此时 duration 已经已知（媒体已加载），立即 seek
    if (engineController.player.state.duration > Duration.zero) {
      engineController.player.seek(seekDuration).then((_) {
        isPlayerReady.value = true;
        loadingMessage.value = '';
      });
      return;
    }

    // 监听 duration 事件，一次性 seek 后取消订阅
    _resumeReadySubscription = engineController.player.stream.duration.listen((duration) {
      if (duration > Duration.zero) {
        engineController.player.seek(seekDuration).then((_) {
          _resumeReadySubscription?.cancel();
          _resumeReadySubscription = null;
          isPlayerReady.value = true;
          loadingMessage.value = '';
        });
      }
    });
  }

  /// 非续播时等待 duration 就绪后标记播放器可用（用于加载提示）
  void _setupInitialReadyListener() {
    if (engineController.player.state.duration > Duration.zero) {
      isPlayerReady.value = true;
      loadingMessage.value = '';
      return;
    }

    late StreamSubscription<Duration> sub;
    sub = engineController.player.stream.duration.listen((duration) {
      if (duration > Duration.zero) {
        isPlayerReady.value = true;
        loadingMessage.value = '';
        sub.cancel();
      }
    });
  }
}
