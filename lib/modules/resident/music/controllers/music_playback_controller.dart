import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/data/repositories/music_repository.dart';
import '../../../../core/data/models/music_data.dart';
import '../../../../core/data/models/music_config.dart';
import '../../../../core/engine/audio/app_audio_service.dart';
import '../engine/music_player_engine.dart';
import 'music_lyrics_controller.dart';
import 'music_playlist_controller.dart';

/// 🎵 独立的播放业务控制器 (Isolated Playback Controller)
///
/// 专门负责：
/// 1. 包裹并调度底层发声引擎 [MusicPlayerEngine]
/// 2. 维护当前正在播放的曲目状态 (currentTrack, position, duration, volume)
/// 3. 提供并实现具体的控制指令 (上一首、下一首、随机播放算法)
class MusicPlaybackController {
  final MusicPlayerEngine _engine = MusicPlayerEngine();
  final MusicPlaylistController playlist;
  final MusicLyricsController lyrics;
  final VoidCallback onUpdate;

  PlaybackMode playMode = PlaybackMode.listLoop;
  MusicTrack? currentTrack;

  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration trackDuration = Duration.zero;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  MusicPlaybackController({
    required this.playlist,
    required this.lyrics,
    required this.onUpdate,
  }) {
    _initEngine();
    _bindGlobalAudio();
  }

  void _syncVolume() {
    _engine.setVolume(AppAudioService.instance.volume);
    onUpdate();
  }

  void _bindGlobalAudio() {
    // 初始同步音量
    _engine.setVolume(AppAudioService.instance.volume);
    
    // 监听全局音量变化并同步到引擎
    AppAudioService.instance.addListener(_syncVolume);
  }

  void _initEngine() {
    _posSub = _engine.onPositionChanged.listen((p) {
      currentPosition = p;
      lyrics.scrollToActiveLyric(p);
      onUpdate();
    });

    _durSub = _engine.onDurationChanged.listen((d) {
      trackDuration = d;
      onUpdate();
    });

    _stateSub = _engine.onPlayingStateChanged.listen((playing) {
      isPlaying = playing;
      onUpdate();
    });

    _completeSub = _engine.onPlayerComplete.listen((_) {
      if (playMode == PlaybackMode.singleLoop && currentTrack != null) {
        // 使用重新加载的方式避免 audioplayers 在 completed 状态下 seek 造成的死锁
        selectTrack(currentTrack!);
      } else {
        playNextTrack();
      }
    });
  }

  Future<void> selectTrack(MusicTrack track, {bool autoplay = true}) async {
    currentTrack = track;
    trackDuration = Duration(seconds: track.duration);
    currentPosition = Duration.zero;
    onUpdate();

    lyrics.loadLyrics(track);

    try {
      final url = await MusicRepository.instance.getAudioPathOrUrl(track);
      if (autoplay) {
        await _engine.playUrl(url);
        await _engine.setVolume(AppAudioService.instance.volume);
      } else {
        await _engine.setUrl(url);
      }
    } catch (e) {
      debugPrint('AudioPlayer error: $e');
    }
  }

  void handlePlaylistRebuilt() {
    if (currentTrack != null && !playlist.tracks.any((t) => t.id == currentTrack!.id)) {
      _engine.stop();
      if (playlist.tracks.isNotEmpty) {
        selectTrack(playlist.tracks.first, autoplay: false);
      } else {
        clearPlayback();
      }
    } else if (currentTrack == null && playlist.tracks.isNotEmpty) {
      selectTrack(playlist.tracks.first, autoplay: false);
    }
    onUpdate();
  }

  void clearPlayback() {
    _engine.stop();
    currentTrack = null;
    currentPosition = Duration.zero;
    trackDuration = Duration.zero;
    lyrics.clearLyrics();
    onUpdate();
  }

  void togglePlayPause() async {
    if (currentTrack == null) return;
    try {
      if (isPlaying) {
        await _engine.pause();
      } else {
        if (!_engine.hasSource) {
          final url = await MusicRepository.instance.getAudioPathOrUrl(currentTrack!);
          await _engine.playUrl(url);
        } else {
          await _engine.resume();
        }
      }
    } catch (e) {
      debugPrint('AudioPlayer play/pause error: $e');
    }
  }

  void playNextTrack() {
    if (playlist.tracks.isEmpty || currentTrack == null) return;
    
    if (playMode == PlaybackMode.shuffle) {
      final random = playlist.tracks[DateTime.now().millisecondsSinceEpoch % playlist.tracks.length];
      selectTrack(random);
      return;
    }

    final idx = playlist.tracks.indexWhere((t) => t.id == currentTrack!.id);
    selectTrack(idx != -1 && idx < playlist.tracks.length - 1 ? playlist.tracks[idx + 1] : playlist.tracks.first);
  }

  void playPrevTrack() {
    if (playlist.tracks.isEmpty || currentTrack == null) return;
    
    if (playMode == PlaybackMode.shuffle) {
      final random = playlist.tracks[DateTime.now().millisecondsSinceEpoch % playlist.tracks.length];
      selectTrack(random);
      return;
    }

    final idx = playlist.tracks.indexWhere((t) => t.id == currentTrack!.id);
    selectTrack(idx > 0 ? playlist.tracks[idx - 1] : playlist.tracks.last);
  }

  void seekTo(Duration position) => _engine.seek(position);

  void dispose() {
    AppAudioService.instance.removeListener(_syncVolume);
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _engine.dispose();
  }
}
