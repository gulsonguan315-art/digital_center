import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/control/superfocus/interaction_manager.dart';
import '../../../../core/control/device_manager/device_manager.dart';
import '../../../../core/data/data_manager.dart';
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

  String? currentSeriesId;
  double _playbackSpeed = 1.0;
  bool _autoSkip = false;
  int _introDuration = 0;
  int _outroDuration = 0;
  bool _isSwitchingEpisode = false;

  double get playbackSpeed => _playbackSpeed;
  bool get autoSkip => _autoSkip;
  int get introDuration => _introDuration;
  int get outroDuration => _outroDuration;

  MediaImmersiveController({
    required String initialItemId,
    required this.onExitRequest,
  }) {
    currentItemIdNotifier = ValueNotifier<String>(initialItemId);
    engineController = MediaEngineController(
      interactionStreamController: interactionStreamController,
    );
    engineController.init(currentItemIdNotifier.value);

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
        if (_introDuration > 0 && pos.inMilliseconds < _introDuration) {
          if (pos.inMilliseconds > 1000 && pos.inMilliseconds < _introDuration - 1000) {
            engineController.player.seek(Duration(milliseconds: _introDuration));
          }
        }
        if (_outroDuration > 0) {
          final total = engineController.player.state.duration.inMilliseconds;
          if (total > 0 && pos.inMilliseconds >= total - _outroDuration) {
            switchEpisode(1);
          }
        }
      }
    });

    _loadSettingsAndApply();
  }

  Future<void> _loadSettingsAndApply() async {
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

  void dispose() {
    _positionSub.cancel();
    _completedSub.cancel();
    seekController.dispose();
    engineController.dispose();
    interactionStreamController.close();
    currentItemIdNotifier.dispose();
  }

  /// 剧集切换逻辑（1 = 下一集, -1 = 上一集）
  Future<bool> switchEpisode(int direction) async {
    if (_isSwitchingEpisode) return false;
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
}
