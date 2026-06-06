import 'package:flutter/material.dart';

import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/control/superfocus/interaction_manager.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/engine/audio/app_audio_service.dart';
import 'music_model.dart';
import 'music_callback.dart';
import 'music_view.dart';
import 'views_components/music_folder_view.dart';
import 'views_components/music_list_view.dart';
import 'views_components/music_lyrics_view.dart';
import 'views_components/music_control_view.dart';
import '../../overlay/music/music_immersive_overlay.dart';

/// 📂 音乐页面主房间 (Music Room - Composition Root)

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
      child:
          widget.child ??
          ValueListenableBuilder(
            valueListenable: SuperFocusManager.instance.topologyNotifier,
            builder: (context, topology, _) {
              final isActive = topology.activePath.contains(
                MusicModel.musicPageId,
              );
              final isEntering =
                  SuperFocusManager.instance.intentionRoomId.value ==
                  MusicModel.musicPageId;

              if (!isActive && !isEntering) {
                return const SizedBox.shrink();
              }

              return ListenableBuilder(
                listenable: _cb,
                builder: (context, _) {
                  // 异常兜底
                  if (_cb.service.playlist.errorMessage != null) {
                    return MusicErrorView(
                      errorMessage: _cb.service.playlist.errorMessage,
                      retrySlot: (builder) => FocusIdentity(
                        id: MusicModel.retryBtnId,
                        onPressed: _cb.retryLoadFolders,
                        builder: builder,
                      ),
                    );
                  }
                  // 首屏 Loading
                  if (_cb.service.playlist.isLoadingFolders) {
                    return const MusicLoadingView();
                  }

                  return MusicPageView(
                    slots: {
                      'music_folder': MusicFolderRoom(cb: _cb),
                      'music_list': MusicListRoom(cb: _cb),
                      'music_lyrics': MusicLyricsRoom(cb: _cb),
                      'music_control': MusicControlRoom(cb: _cb),
                    },
                  );
                },
              );
            },
          ),
    );
  }
}

// =============================================================================
// (二级包工头)
// =============================================================================

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
            focusGeometry: RoundedRectFocusGeometry(
              borderRadius: material.shape.radius,
            ),
            builder: (context, hasFocus) {
              return SuperFocusRoom(
                id: MusicModel.folderZoneId,
                child: MusicFolderView(
                  slots: {
                    'folder_list': MusicFolderList(
                      refreshSlot: (builder, {focusGeometry}) {
                        void action() => cb.forceRefreshFolders();
                        return FocusIdentity(
                          id: 'folder_refresh_btn',
                          onPressed: action,
                          focusGeometry: focusGeometry,
                          builder: (ctx, hasFocus) => builder(ctx, hasFocus, action),
                        );
                      },
                      folderCount: cb.service.playlist.folders.length,
                      folderSlot: (ctx, index, innerBuilder, {focusGeometry}) {
                        final folder = cb.service.playlist.folders[index];
                        final isActive = cb.service.playlist.activeFolderIds.contains(folder.id);
                        void action() => cb.toggleFolder(folder.id);
                        return FocusIdentity(
                          id: 'folder_card_${folder.id}',
                          onPressed: action,
                          focusGeometry: focusGeometry,
                          builder: (ctx, hasFocus) => innerBuilder(
                            ctx, hasFocus, action,
                            folder: folder, isActive: isActive,
                          ),
                        );
                      },
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
            focusGeometry: RoundedRectFocusGeometry(
              borderRadius: material.shape.radius,
            ),
            builder: (context, hasFocus) {
              return SuperFocusRoom(
                id: MusicModel.listZoneId,
                child: MusicListView(
                  trackCount: cb.service.playlist.tracks.length,
                  trackSlot: (ctx, index, innerBuilder, {focusGeometry}) {
                    final track = cb.service.playlist.tracks[index];
                    final isCurrent = cb.service.playback.currentTrack?.id == track.id;
                    void action() => cb.selectTrack(track);
                    return FocusIdentity(
                      id: 'track_row_${track.id}',
                      focusGeometry: focusGeometry,
                      alignment: FocusAlignment.center,
                      onPressed: action,
                      builder: (ctx, hasFocus) => innerBuilder(
                        ctx, hasFocus, action,
                        track: track, isCurrent: isCurrent, isPlaying: cb.service.playback.isPlaying,
                      ),
                    );
                  },
                  isLoadingTracks: cb.service.playlist.isLoadingTracks,
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
          return FocusIdentity(
            id: MusicModel.lyricsZoneId,
            focusGeometry: RoundedRectFocusGeometry(
              borderRadius: material.shape.radius,
            ),
            builder: (context, hasFocus) {
              return SuperFocusRoom(
                id: MusicModel.lyricsZoneId,
                child: MusicLyricsView(
                  parsedLyrics: cb.service.lyrics.parsedLyrics,
                  activeLyricIndex: cb.service.lyrics.getActiveLyricIndex(
                    cb.service.playback.currentPosition,
                  ),
                  isLoadingLyrics: cb.service.lyrics.isLoadingLyrics,
                  scrollController: cb.service.lyrics.scrollController,
                  material: material,
                  hasFocus: hasFocus,
                  currentPosition: cb.service.playback.currentPosition,
                  isPlaying: cb.service.playback.isPlaying,
                  currentOffsetMs: cb.service.lyrics.cumulativeOffsetMs,
                  minusLargeSlot: (builder) => FocusIdentity(
                    id: MusicModel.btnLyricsOffsetMinusId,
                    onPressed: cb.offsetLyricsMinusLarge,
                    focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(6))),
                    builder: builder,
                  ),
                  minusSmallSlot: (builder) => FocusIdentity(
                    id: MusicModel.btnLyricsOffsetMinusSmallId,
                    onPressed: cb.offsetLyricsMinusSmall,
                    focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(6))),
                    builder: builder,
                  ),
                  plusSmallSlot: (builder) => FocusIdentity(
                    id: MusicModel.btnLyricsOffsetPlusSmallId,
                    onPressed: cb.offsetLyricsPlusSmall,
                    focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(6))),
                    builder: builder,
                  ),
                  plusLargeSlot: (builder) => FocusIdentity(
                    id: MusicModel.btnLyricsOffsetPlusId,
                    onPressed: cb.offsetLyricsPlusLarge,
                    focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(6))),
                    builder: builder,
                  ),
                  exportSlot: (builder) => FocusIdentity(
                    id: MusicModel.btnLyricsExportId,
                    onPressed: () async {
                      final success = await cb.exportLyricsToFile();
                      if (success) {}
                    },
                    focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(6))),
                    builder: builder,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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
            focusGeometry: RoundedRectFocusGeometry(
              borderRadius: material.shape.radius,
            ),
            builder: (context, hasFocus) {
              return SuperFocusRoom(
                id: MusicModel.controlZoneId,
                child: Builder(
                  builder: (context) {
                    return MusicControlView(
                      slots: {
                        'control_bar': MusicControlBar(
                          currentTrack: cb.service.playback.currentTrack,
                          currentPosition: cb.service.playback.currentPosition,
                          trackDuration: cb.service.playback.trackDuration,
                          volume: AppAudioService.instance.volume,
                          material: material,
                          onSeek: (ratio) {
                            final ms = (ratio * cb.service.playback.trackDuration.inMilliseconds).toInt();
                            cb.seekTo(Duration(milliseconds: ms));
                          },
                          isPlaying: cb.service.playback.isPlaying,
                          playMode: cb.service.playback.playMode,
                          playModeSlot: (builder, {focusGeometry}) => FocusActionButton(
                            id: MusicModel.btnPlayModeId,
                            onPressed: cb.togglePlayMode,
                            focusGeometry: focusGeometry,
                            builder: (ctx, hasFocus, activate) => builder(ctx, hasFocus, activate),
                          ),
                          fastRewindSlot: (builder, {focusGeometry}) => FocusActionButton(
                            id: MusicModel.btnFastRewindId,
                            onPressed: cb.fastRewind,
                            focusGeometry: focusGeometry,
                            builder: (ctx, hasFocus, activate) => builder(ctx, hasFocus, activate),
                          ),
                          prevSlot: (builder, {focusGeometry}) => FocusActionButton(
                            id: MusicModel.btnPrevId,
                            onPressed: cb.playPrevTrack,
                            focusGeometry: focusGeometry,
                            builder: (ctx, hasFocus, activate) => builder(ctx, hasFocus, activate),
                          ),
                          playPauseSlot: (builder, {focusGeometry}) => FocusActionButton(
                            id: MusicModel.btnPlayId,
                            onPressed: cb.togglePlayPause,
                            focusGeometry: focusGeometry,
                            builder: (ctx, hasFocus, activate) => builder(ctx, hasFocus, activate),
                          ),
                          nextSlot: (builder, {focusGeometry}) => FocusActionButton(
                            id: MusicModel.btnNextId,
                            onPressed: cb.playNextTrack,
                            focusGeometry: focusGeometry,
                            builder: (ctx, hasFocus, activate) => builder(ctx, hasFocus, activate),
                          ),
                          fastForwardSlot: (builder, {focusGeometry}) => FocusActionButton(
                            id: MusicModel.btnFastForwardId,
                            onPressed: cb.fastForward,
                            focusGeometry: focusGeometry,
                            builder: (ctx, hasFocus, activate) => builder(ctx, hasFocus, activate),
                          ),
                          recacheSlot: (builder, {focusGeometry}) => FocusActionButton(
                            id: MusicModel.btnRecacheId,
                            onPressed: cb.reCacheCurrentTrack,
                            focusGeometry: focusGeometry,
                            builder: (ctx, hasFocus, activate) => builder(ctx, hasFocus, activate),
                          ),
                          fullscreenSlot: (builder, {focusGeometry}) {
                            void action() {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  opaque: true, // 设置为 true 阻止底层页面渲染和刷新
                                  transitionDuration: const Duration(milliseconds: 400),
                                  reverseTransitionDuration: const Duration(milliseconds: 300),
                                  pageBuilder: (ctx, anim1, anim2) => FadeTransition(
                                    opacity: anim1,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                                        CurvedAnimation(
                                          parent: anim1,
                                          curve: Curves.easeOutCubic,
                                          reverseCurve: Curves.easeInCubic,
                                        ),
                                      ),
                                      child: const MusicImmersiveOverlay(),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return FocusActionButton(
                              id: MusicModel.btnFullscreenId,
                              onPressed: action,
                              focusGeometry: focusGeometry,
                              builder: (ctx, hasFocus, activate) => builder(ctx, hasFocus, activate),
                            );
                          },
                        ),
                      },
                    );
                  }
                ),
              );
            },
          );
        },
      ),
    );
  }
}
