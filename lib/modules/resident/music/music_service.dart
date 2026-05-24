import 'package:flutter/foundation.dart';
import 'controllers/music_lyrics_controller.dart';
import 'controllers/music_visualizer_controller.dart';
import 'controllers/music_playlist_controller.dart';
import 'controllers/music_playback_controller.dart';

/// 🌍 全局音乐服务 (Application-level Music Service)
/// 它的生命周期与整个 App 同在，绝不随 UI 房间销毁。
class MusicService extends ChangeNotifier {
  static final MusicService instance = MusicService._();

  late final MusicPlaylistController playlist;
  late final MusicPlaybackController playback;
  late final MusicLyricsController lyrics;
  late final MusicVisualizerController visualizer;

  MusicService._() {
    lyrics = MusicLyricsController(onUpdate: notifyListeners);
    visualizer = MusicVisualizerController(onUpdate: notifyListeners);
    
    playlist = MusicPlaylistController(
      onUpdate: notifyListeners,
      onTrackSelected: (track) => playback.selectTrack(track),
      onPlaylistEmptied: () => playback.clearPlayback(),
    );

    playback = MusicPlaybackController(
      playlist: playlist,
      lyrics: lyrics,
      onUpdate: notifyListeners,
    );

    visualizer.startTicker(() => playback.isPlaying);
  }

  // 释放资源（只有在 App 彻底退出时才调用）
  @override
  void dispose() {
    playback.dispose();
    visualizer.dispose();
    lyrics.dispose();
    super.dispose();
  }
}
