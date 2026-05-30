import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/data/data_manager.dart';import '../../../../core/data/repositories/music_repository.dart';
import '../../../../core/data/models/music_data.dart';
import '../views_components/lrc_parser.dart';

/// 📜 独立的歌词处理控制器 (Isolated Lyrics Controller)
///
/// 专门负责：
/// 1. 歌词数据的网络请求与解析
/// 2. 高亮行计算 (getActiveLyricIndex)
/// 3. 歌词面板的自动居中滚动逻辑
class MusicLyricsController {
  bool isLoadingLyrics = false;
  List<LrcLine> parsedLyrics = [];
  final ScrollController scrollController = ScrollController();
  double? _lastScrollTarget;
  
  /// 当前正在加载的音轨 ID，用于竞态检查以防切歌导致旧歌词覆盖新歌词
  String? _loadingTrackId;

  int cumulativeOffsetMs = 0;

  /// 通知外层（MusicCallback）更新 UI
  final VoidCallback onUpdate;

  MusicLyricsController({required this.onUpdate});

  Future<void> loadLyrics(MusicTrack track) async {
    _loadingTrackId = track.id;
    isLoadingLyrics = true;
    _lastScrollTarget = null;
    cumulativeOffsetMs = 0;
    onUpdate();

    try {
      var (lrc, offsetMs) = await MusicRepository.instance.fetchLyrics(track);
      if (_loadingTrackId != track.id) return;

      if (lrc == null) {
        final clean = track.title
            .replaceAll(RegExp(r'\(.*?\)|（.*?）|\[.*?\]|【.*?】'), '')
            .trim();
        if (clean.isNotEmpty && clean != track.title) {
          final cleanTrack = MusicTrack(
            id: track.id,
            title: clean,
            artist: track.artist,
            album: track.album,
            duration: track.duration,
            size: track.size,
            path: track.path,
            coverArtId: track.coverArtId,
          );
          final tuple = await MusicRepository.instance.fetchLyrics(cleanTrack);
          lrc = tuple.$1;
          offsetMs = tuple.$2;
          if (_loadingTrackId != track.id) return;
        }
      }

      if (lrc == null && (track.artist == 'Unknown Artist' || track.artist.trim().isEmpty)) {
        final unknownTrack = MusicTrack(
          id: track.id,
          title: track.title,
          artist: '',
          album: track.album,
          duration: track.duration,
          size: track.size,
          path: track.path,
          coverArtId: track.coverArtId,
        );
        final tuple = await MusicRepository.instance.fetchLyrics(unknownTrack);
        lrc = tuple.$1;
        offsetMs = tuple.$2;
        if (_loadingTrackId != track.id) return;
      }

      if (_loadingTrackId != track.id) return;

      if (lrc != null && lrc.isNotEmpty) {
        parsedLyrics = LrcParser.parse(lrc);
        // 如果有缓存的偏移量，在内存中自动应用
        if (offsetMs != 0) {
          cumulativeOffsetMs = offsetMs;
          _applyOffset(offsetMs);
        }
      } else {
        parsedLyrics = [
          LrcLine(Duration.zero, '未找到同步歌词'),
          LrcLine(Duration.zero, '歌手: ${track.artist}'),
          LrcLine(Duration.zero, '歌名: ${track.title}'),
        ];
      }
    } catch (_) {
      if (_loadingTrackId != track.id) return;
      parsedLyrics = [LrcLine(Duration.zero, '歌词加载失败')];
    }

    isLoadingLyrics = false;
    onUpdate();
  }

  void clearLyrics() {
    _loadingTrackId = null;
    parsedLyrics = [];
    isLoadingLyrics = false;
    _lastScrollTarget = null;
    cumulativeOffsetMs = 0;
    onUpdate();
  }

  int getActiveLyricIndex(Duration currentPosition) {
    for (int i = parsedLyrics.length - 1; i >= 0; i--) {
      if (currentPosition >= parsedLyrics[i].time) return i;
    }
    return 0;
  }

  void scrollToActiveLyric(Duration currentPosition) {
    if (parsedLyrics.isEmpty || !scrollController.hasClients) return;
    final idx = getActiveLyricIndex(currentPosition);
    if (idx == -1) return;
    
    final target = (idx * 36.0).clamp(0.0, scrollController.position.maxScrollExtent);
    if (_lastScrollTarget == target) return;
    _lastScrollTarget = target;
    scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void adjustOffset(int deltaMs) {
    if (parsedLyrics.isEmpty) return;
    
    cumulativeOffsetMs += deltaMs;
    _applyOffset(deltaMs);
    
    onUpdate();
  }

  void _applyOffset(int deltaMs) {
    for (int i = 0; i < parsedLyrics.length; i++) {
      final oldTime = parsedLyrics[i].time;
      final newTimeMs = (oldTime.inMilliseconds + deltaMs).clamp(0, 9999999);
      parsedLyrics[i] = LrcLine(Duration(milliseconds: newTimeMs), parsedLyrics[i].text);
    }
  }

  Future<bool> exportLrcToFile(MusicTrack track) async {
    if (parsedLyrics.isEmpty) return false;

    try {
      final buffer = StringBuffer();
      for (final line in parsedLyrics) {
        final min = (line.time.inMinutes).toString().padLeft(2, '0');
        final sec = (line.time.inSeconds % 60).toString().padLeft(2, '0');
        // 强制 3 位毫秒，解决 Gonic 过滤 2 位毫秒的 Bug
        final ms = (line.time.inMilliseconds % 1000).toString().padLeft(3, '0');
        buffer.writeln('[$min:$sec.$ms] ${line.text}');
      }

      final configDir = DataManager.instance.localStore.configDirPath;
      final exportDir = Directory('$configDir/music_cache/exported_lyrics');
      if (!exportDir.existsSync()) {
        exportDir.createSync(recursive: true);
      }

      // 提取相对路径目录结构，例如：周杰伦/七里香/七里香.lrc
      final trackPath = track.path;
      final lastDot = trackPath.lastIndexOf('.');
      final lrcPath = (lastDot != -1 ? trackPath.substring(0, lastDot) : trackPath) + '.lrc';
      
      final file = File('${exportDir.path}/$lrcPath');
      file.parent.createSync(recursive: true);
      
      await file.writeAsString(buffer.toString());
      
      // 写出外置标准文件的同时，更新本地播放缓存字典的 offset_ms 头，让它在运行 Python 脚本前就能生效
      await MusicRepository.instance.updateLyricsCacheOffset(track, cumulativeOffsetMs, isExported: true);
      
      return true;
    } catch (e) {
      debugPrint('Export LRC Failed: $e');
      return false;
    }
  }

  void dispose() {
    scrollController.dispose();
  }
}
