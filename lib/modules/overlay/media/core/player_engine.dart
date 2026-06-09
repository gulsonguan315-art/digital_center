import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/engine/audio/app_audio_service.dart';
import '../../../../core/control/device_manager/device_manager.dart';
import '../../../resident/media/media_service.dart';
import 'media_seek_controller.dart';
import 'media_playback_reporter.dart';
import 'media_target_resolver.dart';

/// 播放器底层引擎控制器
/// 纯粹负责封装 MediaKit 的初始化、资源释放、全局音量同步，以及播放与进度控制
class PlayerEngine {
  late final Player player;
  late final VideoController videoController;
  late final MediaSeekController seekController;
  late final MediaPlaybackReporter reporter;
  late final ValueNotifier<String> currentItemIdNotifier;
  
  final StreamController<String> interactionStreamController;
  Future<void> Function()? onEpisodeSwitched;

  bool _isSwitchingEpisode = false;
  bool get isSwitchingEpisode => _isSwitchingEpisode;

  PlayerEngine({
    required String initialItemId,
    required this.interactionStreamController,
    this.onEpisodeSwitched,
  }) {
    player = Player();
    player.setVolume(AppAudioService.instance.volume * 100.0);
    videoController = VideoController(player);
    seekController = MediaSeekController(player, interactionStreamController);
    reporter = MediaPlaybackReporter(player);
    currentItemIdNotifier = ValueNotifier(initialItemId);
  }

  void init({int startPositionTicks = 0}) {
    final url = MediaService.instance.streamUrl(currentItemIdNotifier.value);
    player.open(Media(url));

    AppAudioService.instance.addListener(_onGlobalVolumeChanged);
    reporter.start(currentItemIdNotifier.value, startPositionTicks: startPositionTicks);
  }

  void playItem(String itemId) {
    final url = MediaService.instance.streamUrl(itemId);
    player.open(Media(url));
  }

  void play() => player.play();
  void pause() => player.pause();
  void playOrPause() => player.playOrPause();
  
  void seekForward() => seekController.seekRelative(InputSignal.right);
  void seekBackward() => seekController.seekRelative(InputSignal.left);

  Future<bool> switchEpisode(int direction) async {
    if (_isSwitchingEpisode) return false;

    // 立即捕获旧集最后位置并后台异步上报 Stopped，不阻塞新集的解析和播放启动
    // 位置已在调用时同步读取，网络延迟不会影响切集流畅度
    reporter.stopAndReportAsync();
    _isSwitchingEpisode = true;

    try {
      final nextId = await MediaTargetResolver.resolveRelativeEpisode(
        currentItemIdNotifier.value,
        direction,
      );

      if (nextId != null) {
        currentItemIdNotifier.value = nextId;
        playItem(nextId);
        reporter.start(nextId);
        interactionStreamController.add(
          direction > 0 ? 'next_episode' : 'prev_episode',
        );
        if (onEpisodeSwitched != null) {
          await onEpisodeSwitched!();
        }
        return true;
      }

      interactionStreamController.add(
        direction > 0 ? 'error_next_episode' : 'error_prev_episode',
      );
      return false;
    } finally {
      _isSwitchingEpisode = false;
    }
  }

  void pauseForDialog() {
    seekController.wasPlayingBeforeSeek = player.state.playing;
    if (seekController.wasPlayingBeforeSeek) {
      player.pause();
    }
  }

  void resumeIfWasPlayingBeforeSeek() {
    if (!player.state.playing && seekController.wasPlayingBeforeSeek) {
      player.play();
    }
  }

  void _onGlobalVolumeChanged() {
    final vol = AppAudioService.instance.volume * 100.0;
    player.setVolume(vol);
    interactionStreamController.add('音量: ${vol.toInt()}%');
  }

  void dispose() {
    AppAudioService.instance.removeListener(_onGlobalVolumeChanged);
    // 只在尚未执行过 stop 报告时才触发（防止 overlay 退出时双上报）
    if (!reporter.hasStopped) {
      reporter.stopAndReportAsync();
    }
    reporter.dispose();
    seekController.dispose();
    currentItemIdNotifier.dispose();
    player.dispose();
  }
}
