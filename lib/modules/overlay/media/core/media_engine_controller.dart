import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/engine/audio/app_audio_service.dart';
import '../../../resident/media/media_service.dart';

/// 播放器底层引擎控制器
/// 负责封装 MediaKit 的初始化、资源释放以及与全局系统音量的自动同步
class MediaEngineController {
  late final Player player;
  late final VideoController videoController;
  final StreamController<String> interactionStreamController;

  MediaEngineController({required this.interactionStreamController});

  void init(String itemId) {
    player = Player();
    // 初始化时同步全局音量
    player.setVolume(AppAudioService.instance.volume * 100.0);

    videoController = VideoController(player);

    final url = MediaService.instance.streamUrl(itemId);
    player.open(Media(url));

    AppAudioService.instance.addListener(_onGlobalVolumeChanged);
  }

  void playItem(String itemId) {
    final url = MediaService.instance.streamUrl(itemId);
    player.open(Media(url));
  }

  void _onGlobalVolumeChanged() {
    final vol = AppAudioService.instance.volume * 100.0;
    player.setVolume(vol);
    interactionStreamController.add('音量: ${vol.toInt()}%');
  }

  void dispose() {
    AppAudioService.instance.removeListener(_onGlobalVolumeChanged);
    player.dispose();
  }
}
