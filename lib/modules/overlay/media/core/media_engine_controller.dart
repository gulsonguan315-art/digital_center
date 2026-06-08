import 'dart:async';
import 'dart:math';
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

  // 当前播放的条目 ID 和心跳定时器
  String? _currentItemId;
  Timer? _progressTimer;

  /// 每次打开播放器（或切集）时生成的 PlaySessionId。
  /// 用于让 Jellyfin 控制台把我们的播放识别为一个标准会话。
  String? _playSessionId;
  String? get playSessionId => _playSessionId;

  MediaEngineController({required this.interactionStreamController});

  void init(String itemId, {int startPositionTicks = 0}) {
    // 防御性清理：如果有人在同一个实例上多次调用 init，先把旧的 timer/listener 收掉
    _progressTimer?.cancel();
    // 尝试移除旧 listener（如果之前加过）。ChangeNotifier 内部是安全的重复 remove。
    AppAudioService.instance.removeListener(_onGlobalVolumeChanged);

    _currentItemId = itemId;
    _playSessionId = _generatePlaySessionId();

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
    _playSessionId = _generatePlaySessionId(); // 切集视为新的播放会话

    final url = MediaService.instance.streamUrl(itemId);
    player.open(Media(url));

    // 切集时，重新上报一次 Playing（带新的 PlaySessionId）
    _reportProgressToServer(action: 'Playing');
  }

  /// 生成符合 RFC 4122 的 UUID v4，用作 PlaySessionId。
  String _generatePlaySessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // version 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // variant (RFC 4122)
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
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
      playSessionId: _playSessionId,
    );
  }

  void _onGlobalVolumeChanged() {
    final vol = AppAudioService.instance.volume * 100.0;
    player.setVolume(vol);
    interactionStreamController.add('音量: ${vol.toInt()}%');
  }

  void dispose() {
    // 注意：最终的 Playing/Stopped 上报由上层 MediaImmersiveController 负责
    // （通过 stopAndReport / switchEpisode 中的显式上报 + 兜底）。
    // 这里只做资源清理，避免在正常退出路径上重复上报 Stopped。
    _progressTimer?.cancel();
    _progressTimer = null;

    AppAudioService.instance.removeListener(_onGlobalVolumeChanged);
    player.dispose();
  }

  /// 停止进度心跳上报（在 stopAndReport 时调用，避免 Stopped 之后还有 Progress 上报）
  void cancelProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }
}
