import 'package:flutter/material.dart';

import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/engine/audio/app_audio_service.dart';
import 'music_model.dart';
import 'music_callback.dart';
import 'music_view.dart';
import 'views_components/music_folder_view.dart';
import 'views_components/music_list_view.dart';
import 'views_components/music_lyrics_view.dart';
import 'views_components/music_control_view.dart';

/// 📂 音乐页面主房间 (Music Room - Composition Root)
///
/// 职责：
///   1. 创建并持有 [MusicCallback]（状态 + 业务逻辑）
///   2. 监听 callback 变化，将最新数据注入三个 Zone Room
///   3. 按 building_map 中的 +zone 结构把三个 Zone Room 组装进 [MusicPageView]
class MusicRoom extends StatefulWidget {
  final Widget? child;
  const MusicRoom({super.key, this.child});

  static const String roomId = MusicModel.musicPageId;

  @override
  State<MusicRoom> createState() => _MusicRoomState();
}

class _MusicRoomState extends State<MusicRoom> {
  late final MusicCallback _cb;

  @override
  void initState() {
    super.initState();
    _cb = MusicCallback();
  }

  @override
  void dispose() {
    _cb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: MusicModel.musicPageId,
      child: widget.child ??
          ListenableBuilder(
            listenable: _cb,
            builder: (context, _) {
              // 异常兜底
              if (_cb.service.playlist.errorMessage != null) return _buildErrorView(context);
              // 首屏 Loading
              if (_cb.service.playlist.isLoadingFolders) return _buildLoadingView(context);

              return MusicPageView(
                slots: {
                  'music_folder': MusicFolderRoom(cb: _cb),
                  'music_list': MusicListRoom(cb: _cb),
                  'music_lyrics': MusicLyricsRoom(cb: _cb),
                  'music_control': MusicControlRoom(cb: _cb),
                },
              );
            },
          ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (ctx) {
          final colors = ctx.useTheme().colors;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                  strokeWidth: 3.5,
                ),
                const SizedBox(height: 24),
                Text('正在同步 Gonic 视听库...',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (ctx) {
          final material = ctx.useTheme();
          final colors = material.colors;
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: material.shape.radius,
                border: Border.all(color: colors.border, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, color: colors.accent, size: 48),
                  const SizedBox(height: 24),
                  Text('视听中枢连接失败',
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text(
                    _cb.service.playlist.errorMessage ??
                        '无法访问 Gonic 视听库，请验证服务器连通状态或检查 api_endpoints.json 中的配置。',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  FocusIdentity(
                    id: MusicModel.retryBtnId,
                    onPressed: _cb.retryLoadFolders,
                    builder: (ctx2, hasFocus) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: hasFocus ? colors.accent : colors.surface,
                        borderRadius: material.shape.radius,
                        border: Border.all(
                            color: hasFocus ? colors.accent : colors.border,
                            width: 1.5),
                        boxShadow: hasFocus ? material.visual.outerShadows : null,
                      ),
                      child: Text('重新连接',
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Zone Rooms (二级包工头)
// =============================================================================

/// Zone：music_folder — 文件夹选择器区域
class MusicFolderRoom extends StatelessWidget {
  final MusicCallback cb;
  const MusicFolderRoom({super.key, required this.cb});

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (ctx) {
          final material = ctx.useTheme();
          return FocusIdentity(
            id: MusicModel.folderZoneId,
            focusGeometry: RoundedRectFocusGeometry(borderRadius: material.shape.radius),
            builder: (context, hasFocus) {
              return SuperFocusRoom(
                id: MusicModel.folderZoneId,
                child: MusicFolderView(
                  slots: {
                    'folder_list': MusicFolderList(
                      folders: cb.service.playlist.folders,
                      activeFolderIds: cb.service.playlist.activeFolderIds,
                      onToggle: cb.toggleFolder,
                      material: material,
                    ),
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Zone：music_list — 歌曲列表 + 歌词面板区域
class MusicListRoom extends StatelessWidget {
  final MusicCallback cb;
  const MusicListRoom({super.key, required this.cb});

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (ctx) {
          final material = ctx.useTheme();
          return FocusIdentity(
            id: MusicModel.listZoneId,
            focusGeometry: RoundedRectFocusGeometry(borderRadius: material.shape.radius),
            builder: (context, hasFocus) {
              return SuperFocusRoom(
                id: MusicModel.listZoneId,
                child: MusicListView(
                  tracks: cb.service.playlist.tracks,
                  currentTrack: cb.service.playback.currentTrack,
                  isPlaying: cb.service.playback.isPlaying,
                  isLoadingTracks: cb.service.playlist.isLoadingTracks,
                  onSelectTrack: cb.selectTrack,
                  material: material,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 📜 Zone：music_lyrics (无焦点)
class MusicLyricsRoom extends StatelessWidget {
  final MusicCallback cb;
  const MusicLyricsRoom({super.key, required this.cb});

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (ctx) {
          final material = ctx.useTheme();
          // 注意：歌词面板不参与焦点系统，所以没有 FocusIdentity 和 SuperFocusRoom
          return MusicLyricsView(
            parsedLyrics: cb.service.lyrics.parsedLyrics,
            activeLyricIndex: cb.service.lyrics.getActiveLyricIndex(cb.service.playback.currentPosition),
            isLoadingLyrics: cb.service.lyrics.isLoadingLyrics,
            scrollController: cb.service.lyrics.scrollController,
            material: material,
          );
        },
      ),
    );
  }
}

/// Zone：music_control — 底部播放控制区域
class MusicControlRoom extends StatelessWidget {
  final MusicCallback cb;
  const MusicControlRoom({super.key, required this.cb});

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.card,
      child: Builder(
        builder: (ctx) {
          final material = ctx.useTheme();
          return FocusIdentity(
            id: MusicModel.controlZoneId,
            focusGeometry: RoundedRectFocusGeometry(borderRadius: material.shape.radius),
            builder: (context, hasFocus) {
              return SuperFocusRoom(
                id: MusicModel.controlZoneId,
                child: MusicControlView(
                  slots: {
                    'control_bar': MusicControlBar(
                      currentTrack: cb.service.playback.currentTrack,
                      currentPosition: cb.service.playback.currentPosition,
                      trackDuration: cb.service.playback.trackDuration,
                      isPlaying: cb.service.playback.isPlaying,
                      volume: AppAudioService.instance.volume,
                      visualizerHeights: cb.service.visualizer.heights,
                      playMode: cb.service.playback.playMode,
                      material: material,
                      onTogglePlayMode: cb.togglePlayMode,
                      onFastRewind: () {
                        final ms = cb.service.playback.currentPosition.inMilliseconds - 5000;
                        cb.seekTo(Duration(milliseconds: ms.clamp(0, cb.service.playback.trackDuration.inMilliseconds)));
                      },
                      onPrev: cb.playPrevTrack,
                      onPlayPause: cb.togglePlayPause,
                      onNext: cb.playNextTrack,
                      onFastForward: () {
                        final ms = cb.service.playback.currentPosition.inMilliseconds + 5000;
                        cb.seekTo(Duration(milliseconds: ms.clamp(0, cb.service.playback.trackDuration.inMilliseconds)));
                      },
                      onSeek: (ratio) {
                        final ms = (ratio * cb.service.playback.trackDuration.inMilliseconds).toInt();
                        cb.seekTo(Duration(milliseconds: ms));
                      },
                    ),
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
