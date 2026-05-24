import 'package:flutter/material.dart';

import '../../../../core/data/repositories/music_repository.dart';
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

  /// 通知外层（MusicCallback）更新 UI
  final VoidCallback onUpdate;

  MusicLyricsController({required this.onUpdate});

  Future<void> loadLyrics(MusicTrack track) async {
    isLoadingLyrics = true;
    onUpdate();

    try {
      String? lrc = await MusicRepository.instance.fetchLyrics(track.artist, track.title);

      if (lrc == null) {
        final clean = track.title
            .replaceAll(RegExp(r'\(.*?\)|（.*?）|\[.*?\]|【.*?】'), '')
            .trim();
        if (clean.isNotEmpty && clean != track.title) {
          lrc = await MusicRepository.instance.fetchLyrics(track.artist, clean);
        }
      }

      if (lrc == null && (track.artist == 'Unknown Artist' || track.artist.trim().isEmpty)) {
        lrc = await MusicRepository.instance.fetchLyrics('', track.title);
      }

      if (lrc != null && lrc.isNotEmpty) {
        parsedLyrics = LrcParser.parse(lrc);
      } else {
        parsedLyrics = [
          LrcLine(Duration.zero, '未找到同步歌词'),
          LrcLine(Duration.zero, '歌手: ${track.artist}'),
          LrcLine(Duration.zero, '歌名: ${track.title}'),
        ];
      }
    } catch (_) {
      parsedLyrics = [LrcLine(Duration.zero, '歌词加载失败')];
    }

    isLoadingLyrics = false;
    onUpdate();
  }

  void clearLyrics() {
    parsedLyrics = [];
    isLoadingLyrics = false;
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
    scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void dispose() {
    scrollController.dispose();
  }
}
