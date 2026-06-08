import 'dart:async';
import 'dart:math';
import 'package:media_kit/media_kit.dart';
import '../../../../core/log/log.dart';
import '../../../resident/media/media_service.dart';

/// 负责处理向服务端（Jellyfin）的播放进度生命周期上报（独立抽象）
class MediaPlaybackReporter {
  final Player player;
  
  String? _currentItemId;
  String? _playSessionId;
  Timer? _progressTimer;

  bool _isStopped = false;

  MediaPlaybackReporter(this.player);

  /// 开启心跳监控并上报 Playing
  void start(String itemId, {int startPositionTicks = 0}) {
    _isStopped = false;
    _currentItemId = itemId;
    _playSessionId = _generatePlaySessionId();

    _reportProgressToServer(
      action: 'Playing',
      overrideTicks: startPositionTicks,
    );

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (player.state.playing) {
        _reportProgressToServer(action: 'Playing/Progress');
      }
    });
  }

  /// 停止监控并上报最后的退出状态（Playing/Stopped）。适用于切集、退出播放器。
  Future<void> stopAndReport() async {
    if (_isStopped || _currentItemId == null) return;
    _isStopped = true;
    _progressTimer?.cancel();
    
    await _reportProgressToServer(action: 'Playing/Stopped');
    
    _currentItemId = null;
    _playSessionId = null;
  }

  Future<void> _reportProgressToServer({
    required String action,
    int overrideTicks = 0,
  }) async {
    if (_currentItemId == null) return;

    final position = player.state.position;
    
    // 🚨 核心换算：1 微秒(Microsecond) = 1000 纳秒(Nanoseconds)
    // Jellyfin 的 1 Tick = 100 纳秒
    // Flutter的微秒 * 10 = Jellyfin 的 Ticks
    final int positionTicks = overrideTicks > 0
        ? overrideTicks
        : position.inMicroseconds * 10;

    Log.d(
      LogGroup.media,
      '📡 [Reporter] 心跳包: action=$action, itemId=$_currentItemId, ticks=$positionTicks (${positionTicks ~/ 10000000}s)',
    );

    await MediaService.instance.reportPlaybackProgress(
      _currentItemId!,
      positionTicks,
      action: action,
      playSessionId: _playSessionId,
    );
  }

  /// 生成符合 RFC 4122 的 UUID v4，用作 PlaySessionId。
  String _generatePlaySessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  void dispose() {
    _progressTimer?.cancel();
  }
}
