import 'dart:async';
import 'package:media_kit/media_kit.dart';

/// ⚙️ 独立音频播放引擎 (Isolated Music Player Engine)
/// 
/// 负责封装第三方插件 `media_kit` (底层由 FFmpeg 驱动) 的细节，向业务层提供统一、干净的接口。
/// 彻底告别 Windows Media Foundation 的 VBR 时长和时间戳漂移 Bug！
class MusicPlayerEngine {
  final Player _audioPlayer = Player();

  MusicPlayerEngine();

  // ===========================================================================
  // 📡 状态流暴露 (Streams exposed to Business Logic)
  // ===========================================================================

  Stream<Duration> get onPositionChanged => _audioPlayer.stream.position;
  Stream<Duration> get onDurationChanged => _audioPlayer.stream.duration;
  Stream<bool> get onPlayingStateChanged => _audioPlayer.stream.playing;
  Stream<void> get onPlayerComplete => _audioPlayer.stream.completed.where((c) => c).map((_) => null);

  // ===========================================================================
  // 🎮 同步状态提取 (Synchronous State)
  // ===========================================================================

  bool get isPlaying => _audioPlayer.state.playing;
  bool get hasSource => _audioPlayer.state.playlist.medias.isNotEmpty;

  // ===========================================================================
  // 🎛️ 基础控制指令 (Base Player Controls)
  // ===========================================================================

  /// 播放网络直链音频或本地文件
  Future<void> playUrl(String url) async {
    await _audioPlayer.open(Media(url), play: true);
  }

  /// 预加载音频链接但不自动播放
  Future<void> setUrl(String url) async {
    await _audioPlayer.open(Media(url), play: false);
  }

  /// 暂停播放
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// 恢复播放
  Future<void> resume() async {
    await _audioPlayer.play();
  }

  /// 停止播放
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// 跳转至指定时间进度
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// 设置播放器音量 [0.0 - 1.0]
  Future<void> setVolume(double volume) async {
    // media_kit 的音量范围是 0.0 - 100.0
    await _audioPlayer.setVolume(volume * 100.0);
  }

  // ===========================================================================
  // 💀 释放资源
  // ===========================================================================

  void dispose() {
    _audioPlayer.dispose();
  }
}
