import 'dart:math';

import '../../../resident/music/views_components/lrc_parser.dart';

class MoodChunk {
  final String text;
  final double scale; // 大小权重，如 0.8, 1.1, 1.4
  final double alpha; // 透明度权重，如 0.5, 1.0
  final Duration delay; // 逐字入场延迟

  MoodChunk(this.text, this.scale, this.alpha, this.delay);
}

class LyricsChunker {
  static final _random = Random();

  static List<MoodChunk> chunkLine(LrcLine line) {
    if (line.text.trim().isEmpty) return [];

    final rawChunks = line.text.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (rawChunks.isEmpty) return [];

    // 获取底层 awlrc 纯文本（如果存在）
    String awlrcFullText = line.words?.map((e) => e.text).join('') ?? '';
    int awlrcSearchIndex = 0;
    
    final List<Duration> delays = [];
    for (int i = 0; i < rawChunks.length; i++) {
      Duration delay = Duration(milliseconds: i * 150); // Fallback 默认错落延迟
      if (line.words != null) {
        String searchStr = rawChunks[i].replaceAll(RegExp(r'\s+'), '');
        if (searchStr.isNotEmpty) {
          int matchIdx = awlrcFullText.indexOf(searchStr, awlrcSearchIndex);
          if (matchIdx != -1) {
            delay = line.words![matchIdx].relativeStartTime;
            awlrcSearchIndex = matchIdx + searchStr.length;
          } else {
            // 兜底：如果用户修改了文本导致不匹配，尝试只匹配首字母
            matchIdx = awlrcFullText.indexOf(searchStr[0], awlrcSearchIndex);
            if (matchIdx != -1) {
              delay = line.words![matchIdx].relativeStartTime;
              awlrcSearchIndex = matchIdx + 1;
            }
          }
        }
      }
      delays.add(delay);
    }

    if (rawChunks.length == 1) return [MoodChunk(rawChunks[0], 1.2, 1.0, delays[0])];

    // 生成固定但错落的字号权重和透明度权重
    final List<double> scales = [];
    final List<double> alphas = [];
    if (rawChunks.length == 2) {
      scales.addAll([_random.nextBool() ? 0.9 : 1.0, 1.3]);
      alphas.addAll([0.5, 1.0]);

      scales.shuffle(_random);
      alphas.shuffle(_random);
    } else if (rawChunks.length == 3) {
      scales.addAll([0.8, 1.15, 1.4]);
      alphas.addAll([0.3, 0.7, 1.0]);

      scales.shuffle(_random);
      alphas.shuffle(_random);
    } else {
      // 如果块大于3个，随机分配不同大小
      final baseScales = [0.8, 1.0, 1.2, 1.4];
      final baseAlphas = [0.4, 0.6, 0.8, 1.0];
      for (int i = 0; i < rawChunks.length; i++) {
        scales.add(baseScales[_random.nextInt(baseScales.length)]);
        alphas.add(baseAlphas[_random.nextInt(baseAlphas.length)]);
      }
    }

    return List.generate(rawChunks.length, (i) {
      return MoodChunk(rawChunks[i], scales[i], alphas[i], delays[i]);
    });
  }
}
