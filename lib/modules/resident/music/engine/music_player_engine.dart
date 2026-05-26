import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// ⚙️ 独立音频播放引擎 (Isolated Music Player Engine)
/// 
/// 负责封装第三方插件 `audioplayers` 的底层细节，向业务层提供统一、干净的接口。
/// 所有与具体播放控制相关的逻辑均解耦于此。
class MusicPlayerEngine {
  final AudioPlayer _audioPlayer = AudioPlayer();

  MusicPlayerEngine() {
    _audioPlayer.positionUpdater = TimerPositionUpdater(
      interval: const Duration(milliseconds: 100),
      getPosition: _audioPlayer.getCurrentPosition,
    );
  }

  // ===========================================================================
  // 📡 状态流暴露 (Streams exposed to Business Logic)
  // ===========================================================================

  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
  Stream<bool> get onPlayingStateChanged => _audioPlayer.onPlayerStateChanged.map((s) => s == PlayerState.playing);
  Stream<void> get onPlayerComplete => _audioPlayer.onPlayerComplete;

  // ===========================================================================
  // 🎮 同步状态提取 (Synchronous State)
  // ===========================================================================

  bool get isPlaying => _audioPlayer.state == PlayerState.playing;
  bool get hasSource => _audioPlayer.source != null;

  // ===========================================================================
  // 🎛️ 基础控制指令 (Base Player Controls)
  // ===========================================================================

  /// 播放网络直链音频或本地文件
  Future<void> playUrl(String url) async {
    final source = url.startsWith('http') ? UrlSource(url) : DeviceFileSource(url);
    await _audioPlayer.play(source);
  }

  /// 预加载音频链接但不自动播放
  Future<void> setUrl(String url) async {
    final source = url.startsWith('http') ? UrlSource(url) : DeviceFileSource(url);
    await _audioPlayer.setSource(source);
  }

  /// 暂停播放
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// 恢复播放
  Future<void> resume() async {
    await _audioPlayer.resume();
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
    await _audioPlayer.setVolume(volume);
  }

  // ===========================================================================
  // 💀 释放资源
  // ===========================================================================

  void dispose() {
    _audioPlayer.dispose();
  }
}
