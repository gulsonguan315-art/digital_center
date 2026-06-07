import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/engine/audio/app_audio_service.dart';
import '../../../../core/log/log.dart';
import '../../../resident/media/media_service.dart';

/// 播放器底层引擎控制器
/// 负责封装 MediaKit 的初始化、资源释放、全局音量同步，以及 Jellyfin 进度上报心跳
class MediaEngineController {
  late final Player player;
  late final VideoController videoController;
  final StreamController<String> interactionStreamController;

  // 新增：保存当前播放的条目 ID 和心跳定时器
  String? _currentItemId;
  Timer? _progressTimer;

  MediaEngineController({required this.interactionStreamController});

  void init(String itemId, {int startPositionTicks = 0}) {
    _currentItemId = itemId;
    player = Player();
    // 初始化时同步全局音量
    player.setVolume(AppAudioService.instance.volume * 100.0);

    videoController = VideoController(player);

    final url = MediaService.instance.streamUrl(itemId);
    player.open(Media(url));

    AppAudioService.instance.addListener(_onGlobalVolumeChanged);

    // 1. 刚开始播放时，向服务端上报 'Playing' 状态 (告诉服务端我开始看了)
    _reportProgressToServer(action: 'Playing', overrideTicks: startPositionTicks);

    // 2. 开启心跳定时器，每 10 秒上报一次 'Playing/Progress'
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // 只有在真正在播放时才上报进度
      if (player.state.playing) {
        _reportProgressToServer(action: 'Playing/Progress');
      }
    });
  }

  void playItem(String itemId) {
    _currentItemId = itemId;
    final url = MediaService.instance.streamUrl(itemId);
    player.open(Media(url));

    // 切集时，重新上报一次 Playing
    _reportProgressToServer(action: 'Playing');
  }

  /// 核心机制：将当前进度换算为 Jellyfin Ticks 并上传
  void _reportProgressToServer({required String action, int overrideTicks = 0}) {
    if (_currentItemId == null) return;

    final position = player.state.position;

    // 🚨 核心修复：1 微秒(Microsecond) = 1000 纳秒(Nanoseconds)
    // Jellyfin 的 1 Tick = 100 纳秒
    // 所以：Flutter的微秒 * 10 = Jellyfin 的 Ticks
    final int positionTicks = overrideTicks > 0 ? overrideTicks : position.inMicroseconds * 10;

    Log.d(LogGroup.media, '📡 [Player] 心跳包: action=$action, itemId=$_currentItemId, ticks=$positionTicks (${positionTicks ~/ 10000000}s)');

    MediaService.instance.reportPlaybackProgress(
      _currentItemId!,
      positionTicks,
      action: action,
    );
  }

  void _onGlobalVolumeChanged() {
    final vol = AppAudioService.instance.volume * 100.0;
    player.setVolume(vol);
    interactionStreamController.add('音量: ${vol.toInt()}%');
  }

  void dispose() {
    // 3. 销毁时，向服务端上报停止状态 'Playing/Stopped'
    _reportProgressToServer(action: 'Playing/Stopped');

    // 清理定时器
    _progressTimer?.cancel();

    AppAudioService.instance.removeListener(_onGlobalVolumeChanged);
    player.dispose();
  }
}
