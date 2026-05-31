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

    List<String> rawChunks = line.text
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (rawChunks.isEmpty) return [];

    // 兜底策略：如果没有手动加 '|' 分隔符，且句子较长，则自动按空格或随机断句
    if (rawChunks.length == 1 && !line.text.contains('|')) {
      final text = rawChunks[0];
      if (text.contains(' ')) {
        // 如果自带空格（如英文或带停顿的中文），按空格切割
        rawChunks = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      } else if (text.length > 3 && !RegExp(r'[a-zA-Z]').hasMatch(text)) {
        // 纯中文字符无空格（排除包含英文字母的情况防止撕裂单词），随机切成 2 到 3 块，制造错落感
        int targetChunks = _random.nextBool() ? 2 : 3;
        targetChunks = targetChunks.clamp(1, text.length);
        
        Set<int> splitIndices = {};
        while (splitIndices.length < targetChunks - 1) {
          splitIndices.add(1 + _random.nextInt(text.length - 1));
        }
        
        final sortedSplits = splitIndices.toList()..sort();
        rawChunks = [];
        int start = 0;
        for (int split in sortedSplits) {
          rawChunks.add(text.substring(start, split));
          start = split;
        }
        rawChunks.add(text.substring(start));
      }
    }

    // 获取底层 awlrc 纯文本（如果存在）
    String awlrcFullText = line.words?.map((e) => e.text).join('') ?? '';
    int awlrcSearchIndex = 0;

    // 构建字符索引到 Word 索引的映射，解决 awlrc 字符长度和 words 数组长度不一致导致的越界 Bug
    final List<int> charToWordIndex = [];
    if (line.words != null) {
      for (int i = 0; i < line.words!.length; i++) {
        for (int j = 0; j < line.words![i].text.length; j++) {
          charToWordIndex.add(i);
        }
      }
    }

    final List<Duration> delays = [];
    for (int i = 0; i < rawChunks.length; i++) {
      Duration delay = Duration(milliseconds: i * 150); // Fallback 默认错落延迟
      if (line.words != null && charToWordIndex.isNotEmpty) {
        String searchStr = rawChunks[i].replaceAll(RegExp(r'\s+'), '');
        if (searchStr.isNotEmpty) {
          int matchIdx = awlrcFullText.indexOf(searchStr, awlrcSearchIndex);
          if (matchIdx != -1) {
            // 使用映射表安全获取 word index
            int wordIdx = charToWordIndex[matchIdx];
            delay = line.words![wordIdx].relativeStartTime;
            awlrcSearchIndex = matchIdx + searchStr.length;
          } else {
            // 兜底：如果用户修改了文本导致不匹配，尝试只匹配首字母
            matchIdx = awlrcFullText.indexOf(searchStr[0], awlrcSearchIndex);
            if (matchIdx != -1) {
              int wordIdx = charToWordIndex[matchIdx];
              delay = line.words![wordIdx].relativeStartTime;
              awlrcSearchIndex = matchIdx + 1;
            }
          }
        }
      }
      delays.add(delay);
    }

    if (rawChunks.length == 1)
      return [MoodChunk(rawChunks[0], 1.2, 1.0, delays[0])];

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
      alphas.addAll([0.5, 0.75, 1.0]);

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
