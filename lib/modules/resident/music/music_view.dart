import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../core/data/repositories/music_repository.dart';
import '../../../core/data/models/music_data.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/control/superfocus/focus_widgets.dart';

/// 🖥️ 音乐中心主页面排版视图 (Music View Coordinator)
/// 完美复刻用户设计的经典四板块网格排版系统：
/// 1. 左上：物理文件夹选择器 (Horizontal Folders Slider)
/// 2. 左下：无损歌曲播放列表 (Vertical Playlist Table)
/// 3. 右侧：LRC 时间轴动态同步歌词空间 (Scrolling Lyrics Display)
/// 4. 底部：全宽流媒体播放控制中枢 + 高精度进度条 (Playback Controls + Progress Bar)
class MusicView extends StatefulWidget {
  const MusicView({super.key});

  @override
  State<MusicView> createState() => _MusicViewState();
}

class _MusicViewState extends State<MusicView> {
  // --- 数据与加载状态 ---
  List<MusicFolder> _folders = [];
  List<MusicTrack> _tracks = [];
  bool _isLoadingFolders = true;
  bool _isLoadingTracks = false;
  String? _errorMessage;

  // --- 当前选中的实体与多选状态 ---
  final Map<String, List<MusicTrack>> _folderTracksMap = {};
  final Set<String> _activeFolderIds = {};
  MusicTrack? _currentTrack;

  // --- 歌词同步解析 ---
  bool _isLoadingLyrics = false;
  List<LrcLine> _parsedLyrics = [];
  final ScrollController _lyricsScrollController = ScrollController();

  // --- 播放状态与高精度模拟时钟 (Safe Playback & Progress Simulation) ---
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _trackDuration = Duration.zero;
  double _volume = 0.8;

  // --- 真实音频流播放器核心 (AudioPlayer Integrator) ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  // --- 动效控制 ---
  final List<double> _visualizerHeights = List.generate(8, (index) => 4.0);
  Timer? _visualizerTimer;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _loadGonicFolders();
    _startVisualizerTicker();
  }

  void _initAudioPlayer() {
    _audioPlayer.positionUpdater = TimerPositionUpdater(
      interval: const Duration(milliseconds: 100),
      getPosition: _audioPlayer.getCurrentPosition,
    );

    _posSub = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _currentPosition = p;
          _scrollToActiveLyric();
        });
      }
    });

    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _trackDuration = d;
        });
      }
    });

    _stateSub = _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) {
        setState(() {
          _isPlaying = s == PlayerState.playing;
        });
      }
    });

    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        _playNextTrack();
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.dispose();
    _visualizerTimer?.cancel();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 📡 1. 数据层接口交互与联动
  // ---------------------------------------------------------------------------

  /// 后台异步获取 Gonic 顶级物理文件夹目录
  Future<void> _loadGonicFolders() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFolders = true;
      _errorMessage = null;
    });

    try {
      final isServerAlive = await MusicRepository.instance.pingServer();
      if (!isServerAlive) {
        throw Exception("无法连通 Gonic 音乐服务，请检查服务器运行状态。");
      }

      final folders = await MusicRepository.instance.fetchRootFolders();
      if (mounted) {
        setState(() {
          _folders = folders;
          _isLoadingFolders = false;
        });

        // 默认激活并加载第一个文件夹的歌曲
        if (folders.isNotEmpty) {
          _toggleFolder(folders.first.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoadingFolders = false;
        });
      }
    }
  }

  /// 切换物理文件夹的激活状态 (多选模式)
  Future<void> _toggleFolder(String folderId) async {
    if (!mounted) return;

    if (_activeFolderIds.contains(folderId)) {
      // 已经激活，再次点击取消激活并从列表移除歌曲
      setState(() {
        _activeFolderIds.remove(folderId);
        _rebuildPlaylist();
      });
    } else {
      // 未激活，激活并异步拉取其下属歌曲
      setState(() {
        _activeFolderIds.add(folderId);
        _isLoadingTracks = true;
      });

      try {
        if (!_folderTracksMap.containsKey(folderId)) {
          final contents = await MusicRepository.instance.fetchDirectoryContents(folderId);
          final List<MusicTrack> folderTracks = contents['tracks'] as List<MusicTrack>? ?? [];
          _folderTracksMap[folderId] = folderTracks;
        }

        if (mounted) {
          setState(() {
            _isLoadingTracks = false;
            _rebuildPlaylist();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingTracks = false;
          });
        }
      }
    }
  }

  /// 依据当前所有已激活的文件夹，重构播放列表排序并安全处理当前曲目
  void _rebuildPlaylist() {
    final List<MusicTrack> newPlaylist = [];
    
    // 按顶层文件夹的展现顺序依次拼装，确保列表顺序的确定性
    for (final folder in _folders) {
      if (_activeFolderIds.contains(folder.id)) {
        final tracksOfFolder = _folderTracksMap[folder.id];
        if (tracksOfFolder != null) {
          newPlaylist.addAll(tracksOfFolder);
        }
      }
    }

    setState(() {
      _tracks = newPlaylist;

      // 如果当前播放曲目不在新列表里，说明对应的文件夹被停用了
      if (_currentTrack != null && !_tracks.any((t) => t.id == _currentTrack!.id)) {
        _audioPlayer.stop(); // 停止当前硬件播放
        if (_tracks.isNotEmpty) {
          _selectTrack(_tracks.first, autoplay: false);
        } else {
          _currentTrack = null;
          _currentPosition = Duration.zero;
          _trackDuration = Duration.zero;
          _parsedLyrics = [];
        }
      } else if (_currentTrack == null && _tracks.isNotEmpty) {
        // 如果当前没有曲目但有了新进的歌曲，则载入第一首备用
        _selectTrack(_tracks.first, autoplay: false);
      }
    });
  }

  /// 选定歌曲并开始拉取歌词与播放
  Future<void> _selectTrack(MusicTrack track, {bool autoplay = true}) async {
    if (!mounted) return;
    setState(() {
      _currentTrack = track;
      _trackDuration = Duration(seconds: track.duration);
      _currentPosition = Duration.zero;
      _parsedLyrics = [];
    });

    _loadLyrics(track);

    if (autoplay) {
      try {
        final streamUrl = await MusicRepository.instance.getAudioStreamUrl(track.id);
        await _audioPlayer.play(UrlSource(streamUrl));
        await _audioPlayer.setVolume(_volume);
      } catch (e) {
        debugPrint("AudioPlayer play error: $e");
      }
    } else {
      try {
        final streamUrl = await MusicRepository.instance.getAudioStreamUrl(track.id);
        await _audioPlayer.setSource(UrlSource(streamUrl));
      } catch (e) {
        debugPrint("AudioPlayer setSource error: $e");
      }
    }
  }

  /// 拉取并解析歌词
  Future<void> _loadLyrics(MusicTrack track) async {
    if (!mounted) return;
    setState(() {
      _isLoadingLyrics = true;
    });

    try {
      final lrcText = await MusicRepository.instance.fetchLyrics(track.artist, track.title);
      if (mounted) {
        if (lrcText != null && lrcText.isNotEmpty) {
          setState(() {
            _parsedLyrics = LrcParser.parse(lrcText);
            _isLoadingLyrics = false;
          });
        } else {
          setState(() {
            _parsedLyrics = [LrcLine(Duration.zero, "未找到同步歌词")];
            _isLoadingLyrics = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _parsedLyrics = [LrcLine(Duration.zero, "歌词加载失败")];
          _isLoadingLyrics = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 🎛️ 2. 真实音频播放控制核心 (AudioPlayer Control Center)
  // ---------------------------------------------------------------------------

  void _togglePlayPause() async {
    if (_currentTrack == null) return;
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.source == null) {
          final streamUrl = await MusicRepository.instance.getAudioStreamUrl(_currentTrack!.id);
          await _audioPlayer.play(UrlSource(streamUrl));
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      debugPrint("AudioPlayer play/pause error: $e");
    }
  }

  void _playNextTrack() {
    if (_tracks.isEmpty || _currentTrack == null) return;
    final currentIndex = _tracks.indexWhere((t) => t.id == _currentTrack!.id);
    if (currentIndex != -1 && currentIndex < _tracks.length - 1) {
      _selectTrack(_tracks[currentIndex + 1]);
    } else {
      _selectTrack(_tracks.first);
    }
  }

  void _playPrevTrack() {
    if (_tracks.isEmpty || _currentTrack == null) return;
    final currentIndex = _tracks.indexWhere((t) => t.id == _currentTrack!.id);
    if (currentIndex > 0) {
      _selectTrack(_tracks[currentIndex - 1]);
    } else {
      _selectTrack(_tracks.last);
    }
  }

  /// 歌词随时间轴自动滚动算法
  void _scrollToActiveLyric() {
    if (_parsedLyrics.isEmpty || !_lyricsScrollController.hasClients) return;
    final activeIndex = _getActiveLyricIndex();
    if (activeIndex != -1) {
      final double targetOffset = activeIndex * 36.0 - 100.0;
      _lyricsScrollController.animateTo(
        targetOffset.clamp(0.0, _lyricsScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  int _getActiveLyricIndex() {
    for (int i = _parsedLyrics.length - 1; i >= 0; i--) {
      if (_currentPosition >= _parsedLyrics[i].time) {
        return i;
      }
    }
    return 0;
  }

  /// 均衡器频域动画时钟
  void _startVisualizerTicker() {
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) return;
      if (_isPlaying) {
        setState(() {
          for (int i = 0; i < _visualizerHeights.length; i++) {
            _visualizerHeights[i] = 4.0 + (i % 2 == 0 ? 16.0 : 24.0) * (0.3 + 0.7 * (i % 3 == 0 ? 0.8 : 0.4));
          }
        });
      } else {
        setState(() {
          _visualizerHeights.fillRange(0, _visualizerHeights.length, 4.0);
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 🖥️ 3. 页面布局与卡片渲染 (Grid Dashboard Design)
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ThemeIdentity(
        role: ThemeRole.card,
        child: Builder(
          builder: (context) {
            final material = context.useTheme();
            final colors = material.colors;

            // 异常兜底：网路或服务报错
            if (_errorMessage != null) {
              return _buildErrorState(material);
            }

            // 物理首屏 Loading
            if (_isLoadingFolders) {
              return _buildLoadingState(colors);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // =================== 🌟 上部核心视听空间 (Folders + Playlist + Lyrics) ===================
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 左半防区：包含文件夹 (上) + 播放列表 (下)
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              // 1.1 左上：物理文件夹选择器
                              _buildFoldersSection(material),
                              const SizedBox(height: 16),

                              // 1.2 左下：歌曲播放列表表盘
                              Expanded(
                                child: _buildPlaylistSection(material),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 右半防区：独立歌词显示显示板
                        Expanded(
                          flex: 2,
                          child: _buildLyricsSection(material),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // =================== 🌟 底部流媒体控制中枢 + 进度条 ===================
                  _buildPlaybackControlSection(material),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📦 4. 各功能模块详细卡片构建
  // ---------------------------------------------------------------------------

  /// 📂 [左上角]：物理根文件夹横向滑动选择器 (Folders Section)
  Widget _buildFoldersSection(dynamic material) {
    final colors = material.colors;

    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: material.shape.radius,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '物理媒体库目录 (Gonic)',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final isActive = _activeFolderIds.contains(folder.id);
                final focusId = 'folder_card_${folder.id}';

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: FocusIdentity(
                    id: focusId,
                    onPressed: () => _toggleFolder(folder.id),
                    builder: (context, hasFocus) {
                      final activeColor = hasFocus ? colors.accent : (isActive ? colors.accent.withValues(alpha: 0.2) : colors.surface);
                      final textColor = hasFocus ? Colors.white : (isActive ? colors.accent : colors.textPrimary);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasFocus || isActive ? colors.accent : colors.border,
                            width: 1.5,
                          ),
                          boxShadow: hasFocus ? material.visual.outerShadows : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? Icons.folder_special_rounded : Icons.folder_open_rounded,
                              color: hasFocus ? Colors.white : (isActive ? colors.accent : colors.textSecondary),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              folder.name,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🎶 [左下角]：歌曲列表 (Playlist Section)
  Widget _buildPlaylistSection(dynamic material) {
    final colors = material.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: material.shape.radius,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '播放列表 (${_tracks.length} 首)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              if (_isLoadingTracks)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tracks.isEmpty
                ? Center(
                    child: Text(
                      _isLoadingTracks ? '正在扫描音轨...' : '此物理文件夹内暂无歌曲',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: _tracks.length,
                    itemBuilder: (context, index) {
                      final track = _tracks[index];
                      final isCurrent = _currentTrack?.id == track.id;
                      final focusId = 'track_row_${track.id}';

                      return FocusIdentity(
                        id: focusId,
                        onPressed: () => _selectTrack(track),
                        builder: (context, hasFocus) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: hasFocus
                                  ? colors.accent.withValues(alpha: 0.1)
                                  : (isCurrent ? colors.accent.withValues(alpha: 0.05) : Colors.transparent),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasFocus ? colors.accent : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // 序号或播放动效
                                SizedBox(
                                  width: 24,
                                  child: isCurrent && _isPlaying
                                      ? Icon(Icons.volume_up_rounded, color: colors.accent, size: 14)
                                      : Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: isCurrent ? colors.accent : colors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 8),

                                // 歌名
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    track.title,
                                    style: TextStyle(
                                      color: isCurrent ? colors.accent : colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // 歌手
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    track.artist,
                                    style: TextStyle(
                                      color: isCurrent ? colors.accent.withValues(alpha: 0.8) : colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // 格式大小
                                Text(
                                  track.formattedSize,
                                  style: TextStyle(
                                    color: colors.textSecondary.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // 时长
                                Text(
                                  track.formattedDuration,
                                  style: TextStyle(
                                    color: isCurrent ? colors.accent : colors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 📝 [右侧]：歌词面板 (Lyrics Section)
  Widget _buildLyricsSection(dynamic material) {
    final colors = material.colors;
    final activeIndex = _getActiveLyricIndex();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: material.shape.radius,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LRC 同步歌词 (同步中)',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingLyrics
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                    ),
                  )
                : _parsedLyrics.isEmpty
                    ? Center(
                        child: Text(
                          '暂无播放歌曲',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                      )
                    : ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.15, 0.85, 1.0],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ListView.builder(
                          controller: _lyricsScrollController,
                          itemCount: _parsedLyrics.length,
                          itemBuilder: (context, index) {
                            final line = _parsedLyrics[index];
                            final isActive = index == activeIndex;

                            return Container(
                              height: 36,
                              alignment: Alignment.center,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 250),
                                scale: isActive ? 1.12 : 1.0,
                                child: Text(
                                  line.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isActive ? colors.accent : colors.textSecondary.withValues(alpha: 0.8),
                                    fontSize: isActive ? 15 : 13,
                                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// 🎚️ [底部全宽]：播放控制 + 进度条中枢 (Playback Control Section)
  Widget _buildPlaybackControlSection(dynamic material) {
    final colors = material.colors;

    // 格式化秒级时间
    String formatTime(Duration d) {
      final min = d.inMinutes;
      final sec = d.inSeconds % 60;
      return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }

    final double progress = _trackDuration.inMilliseconds > 0
        ? (_currentPosition.inMilliseconds / _trackDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: material.shape.radius,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 顶部进度条
          Row(
            children: [
              Text(
                formatTime(_currentPosition),
                style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: FocusIdentity(
                    id: 'music_progress_slider',
                    builder: (context, hasFocus) {
                      return Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent) {
                            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                              final targetSec = (_currentPosition.inSeconds - 5).clamp(0, _trackDuration.inSeconds);
                              _audioPlayer.seek(Duration(seconds: targetSec));
                              return KeyEventResult.handled;
                            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                              final targetSec = (_currentPosition.inSeconds + 5).clamp(0, _trackDuration.inSeconds);
                              _audioPlayer.seek(Duration(seconds: targetSec));
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: hasFocus ? 5.0 : 3.0,
                            activeTrackColor: colors.accent,
                            inactiveTrackColor: colors.border,
                            thumbColor: colors.accent,
                            overlayColor: colors.accent.withValues(alpha: 0.1),
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: hasFocus ? 8.0 : 6.0),
                          ),
                          child: Slider(
                            value: progress,
                            focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
                            onChanged: (val) {
                              final targetSeconds = (val * _trackDuration.inSeconds).toInt();
                              _audioPlayer.seek(Duration(seconds: targetSeconds));
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Text(
                formatTime(_trackDuration),
                style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. 底部功能控制 Row
          Row(
            children: [
              // A. 左侧：歌曲基本信息 (不显示图片，歌名加上歌手)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentTrack != null
                          ? '${_currentTrack!.title} - ${_currentTrack!.artist}'
                          : '暂无播放歌曲',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_currentTrack != null && _currentTrack!.album.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _currentTrack!.album,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // B. 中间：流媒体播放按钮组合
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 上一首
                    FocusIdentity(
                      id: 'music_btn_prev',
                      onPressed: _playPrevTrack,
                      builder: (context, hasFocus) => IconButton(
                        focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
                        icon: const Icon(Icons.skip_previous_rounded),
                        color: hasFocus ? colors.accent : colors.textPrimary,
                        onPressed: _playPrevTrack,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 播放 / 暂停 (核心大钮)
                    FocusIdentity(
                      id: 'music_btn_play',
                      onPressed: _togglePlayPause,
                      builder: (context, hasFocus) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasFocus ? colors.accent : colors.surface,
                          border: Border.all(color: colors.accent, width: 2),
                          boxShadow: hasFocus ? material.visual.outerShadows : null,
                        ),
                        child: IconButton(
                          focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
                          icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          color: hasFocus ? Colors.white : colors.accent,
                          onPressed: _togglePlayPause,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 下一首
                    FocusIdentity(
                      id: 'music_btn_next',
                      onPressed: _playNextTrack,
                      builder: (context, hasFocus) => IconButton(
                        focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
                        icon: const Icon(Icons.skip_next_rounded),
                        color: hasFocus ? colors.accent : colors.textPrimary,
                        onPressed: _playNextTrack,
                      ),
                    ),
                  ],
                ),
              ),

              // C. 右侧：动态均衡波形条 + 音量控制
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 波形条动画 (Wave Visualizer)
                    Row(
                      children: List.generate(_visualizerHeights.length, (idx) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 2.5,
                          height: _visualizerHeights[idx],
                          margin: const EdgeInsets.only(right: 2.5),
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 16),

                    // 音量微型控制
                    Icon(
                      _volume == 0
                          ? Icons.volume_off_rounded
                          : (_volume < 0.4 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                      color: colors.textSecondary,
                      size: 16,
                    ),
                    FocusIdentity(
                      id: 'music_volume_slider',
                      builder: (context, hasFocus) {
                        return Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                final targetVol = (_volume - 0.05).clamp(0.0, 1.0);
                                setState(() {
                                  _volume = targetVol;
                                });
                                _audioPlayer.setVolume(targetVol);
                                return KeyEventResult.handled;
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                final targetVol = (_volume + 0.05).clamp(0.0, 1.0);
                                setState(() {
                                  _volume = targetVol;
                                });
                                _audioPlayer.setVolume(targetVol);
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: SizedBox(
                            width: 70,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: hasFocus ? 4.0 : 2.0,
                                activeTrackColor: colors.accent,
                                inactiveTrackColor: colors.border,
                                thumbColor: colors.accent,
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: hasFocus ? 6.0 : 4.0),
                              ),
                              child: Slider(
                                value: _volume,
                                focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
                                onChanged: (val) {
                                  setState(() {
                                    _volume = val;
                                  });
                                  _audioPlayer.setVolume(val);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 💀 5. 异常情况 UI 渲染
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState(dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
            strokeWidth: 3.5,
          ),
          const SizedBox(height: 24),
          Text(
            '正在同步 Gonic 视听库...',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic material) {
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
            Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 48),
            const SizedBox(height: 24),
            Text(
              '视听中枢连接失败',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? '无法访问 Gonic (http://192.168.0.2:4747)，请验证服务器连通状态。',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            FocusIdentity(
              id: 'music_retry_btn',
              onPressed: _loadGonicFolders,
              builder: (context, hasFocus) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: hasFocus ? colors.accent : colors.surface,
                  borderRadius: material.shape.radius,
                  border: Border.all(color: hasFocus ? colors.accent : colors.border, width: 1.5),
                  boxShadow: hasFocus ? material.visual.outerShadows : null,
                ),
                child: Text(
                  '重新连接',
                  style: TextStyle(
                    color: hasFocus ? Colors.white : colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📝 6. 高效率 LRC 歌词数据单行解析器与数据载体 (Lrc Data Struct & Parser)
// -----------------------------------------------------------------------------

class LrcLine {
  final Duration time;
  final String text;
  LrcLine(this.time, this.text);
}

class LrcParser {
  /// LRC 解析核心算法：支持 `[mm:ss]` 以及高精度 `[mm:ss.xx]` 或 `[mm:ss.xxx]`
  static List<LrcLine> parse(String text) {
    final List<LrcLine> lines = [];
    final regExp = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\](.*)');

    for (final line in text.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        
        final msStr = match.group(3) ?? '0';
        int msVal = 0;
        if (msStr.length == 1) {
          msVal = int.parse(msStr) * 100;
        } else if (msStr.length == 2) {
          msVal = int.parse(msStr) * 10;
        } else if (msStr.length >= 3) {
          msVal = int.parse(msStr.substring(0, 3));
        }
        
        final content = match.group(4)!.trim();

        // 允许空歌词行，以便正确处理器乐/前奏静音段
        final duration = Duration(
          minutes: min,
          seconds: sec,
          milliseconds: msVal,
        );
        lines.add(LrcLine(duration, content));
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }
}
