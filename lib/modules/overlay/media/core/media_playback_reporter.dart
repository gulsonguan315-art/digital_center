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

  /// 记录本次播放会话期间实际触发的 “Playing/Progress” 心跳次数。
  /// 用于过滤极短播放（<10s）的 Stopped 上报，避免用户连续切集/误触时污染 resume 位置。
  int _progressReportCount = 0;

  MediaPlaybackReporter(this.player);

  /// 开启心跳监控并上报 Playing
  void start(String itemId, {int startPositionTicks = 0}) {
    _isStopped = false;
    _currentItemId = itemId;
    _playSessionId = _generatePlaySessionId();
    _progressReportCount = 0; // 新会话，重置进度计数

    _reportProgressToServer(
      action: 'Playing',
      overrideTicks: startPositionTicks,
    );

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (player.state.playing) {
        _reportProgressToServer(action: 'Playing/Progress');
        _progressReportCount++;
      }
    });
  }

  /// 停止监控并上报最后的退出状态（Playing/Stopped）。
  ///
  /// 这个版本会 **await** 完成后再返回。
  /// 目前主要作为兼容保留，实际切集和退出都已改用异步版本。
  ///
  /// 注意：内部会做“最少播放10秒”筛选，短播放不会触发 Stopped 上报。
  Future<void> stopAndReport() async {
    if (_isStopped || _currentItemId == null) return;

    _isStopped = true;
    _progressTimer?.cancel();

    final itemId = _currentItemId!;
    final playSessionId = _playSessionId;
    final positionTicks = player.state.position.inMicroseconds * 10;

    _currentItemId = null;
    _playSessionId = null;

    if (!_shouldReportStopped()) {
      _progressReportCount = 0;
      return;
    }

    await _reportStoppedToServer(
      itemId: itemId,
      positionTicks: positionTicks,
      playSessionId: playSessionId,
    );
  }

  /// 立即捕获最后位置并在后台异步上报 Stopped（推荐用于切集和退出）。
  ///
  /// - 位置在调用瞬间同步读取（保证准确）
  /// - 取消心跳定时器
  /// - 直接返回，不等待 HTTP 完成
  /// - 新集的 start() / 播放可以马上开始，不会因为网络延迟卡住
  ///
  /// 内部包含“最少播放 ~10 秒”筛选：
  ///   如果本次会话尚未触发过进度心跳（即播放时长 < 10s），则**完全跳过** Stopped 上报。
  ///   这能有效过滤连续快速切集、误触后立刻切回等几乎没观看的情况，避免无意义地上报污染 Jellyfin 的 resume 位置和播放历史。
  ///
  /// 适用于：
  /// - 用户主动退出播放器（overlay 返回详情页）
  /// - 上下切集（switchEpisode）
  ///
  /// 用户可接受的权衡：真正有意义的 Stopped 上报最快也要等到播放满 10s 左右才会产生（由心跳定时器驱动）。
  void stopAndReportAsync() {
    if (_isStopped || _currentItemId == null) return;

    _isStopped = true;
    _progressTimer?.cancel();

    final itemId = _currentItemId!;
    final playSessionId = _playSessionId;
    final positionTicks = player.state.position.inMicroseconds * 10;

    _currentItemId = null;
    _playSessionId = null;

    if (!_shouldReportStopped()) {
      _progressReportCount = 0;
      return;
    }

    // 后台执行，不阻塞调用者
    _reportStoppedToServer(
      itemId: itemId,
      positionTicks: positionTicks,
      playSessionId: playSessionId,
    );
  }

  bool get hasStopped => _isStopped;

  /// 是否应该发送最终的 Playing/Stopped 上报。
  /// 规则：只有当本次会话至少触发过 1 次 10s 进度心跳（即实际播放 >= ~10s）才上报。
  /// 这样可以过滤掉用户连续快速切集、误触后立刻切回来等“几乎没看”的情况，避免污染 Jellyfin 的 resume 位置和播放历史。
  bool _shouldReportStopped() {
    if (_progressReportCount < 1) {
      Log.d(
        LogGroup.media,
        '⏭️ [Reporter] 本次播放时长 < 10s（尚未触发任何进度心跳），跳过 Playing/Stopped 上报，避免短时切集/误触污染 resume 位置',
      );
      return false;
    }
    return true;
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

  /// 专门用于最终 Stopped 上报的后台/前台辅助方法（使用已快照的数据，不依赖实例字段）。
  Future<void> _reportStoppedToServer({
    required String itemId,
    required int positionTicks,
    String? playSessionId,
  }) async {
    Log.d(
      LogGroup.media,
      '📡 [Reporter] 最终停止上报(后台安全): itemId=$itemId, ticks=$positionTicks (${positionTicks ~/ 10000000}s)',
    );

    try {
      await MediaService.instance.reportPlaybackProgress(
        itemId,
        positionTicks,
        action: 'Playing/Stopped',
        playSessionId: playSessionId,
      );
    } catch (_) {
      // 静默失败，上报不应该阻塞或崩溃退出流程
    }
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
    _progressReportCount = 0;
  }
}
