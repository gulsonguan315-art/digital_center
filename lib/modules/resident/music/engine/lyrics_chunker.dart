import 'dart:math';
import 'package:flutter/material.dart';

import '../../../resident/music/views_components/lrc_parser.dart';

class MoodChunk {
  final String text;
  final double scale; // 大小权重
  final double alpha; // 透明度权重
  final Duration delay; // 逐字入场延迟
  final Color color; // 随机颜色

  MoodChunk(this.text, this.scale, this.alpha, this.delay, this.color);
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

    // 生成原先的 alpha 权重，并直接将其映射到 RGB 通道，实现固定的黑白灰随机色调
    final List<double> alphas = [];
    final List<double> scales = [];
    if (rawChunks.length == 1) {
      alphas.add(1.0);
      scales.add(1.2);
    } else if (rawChunks.length == 2) {
      alphas.addAll([0.5, 1.0]);
      alphas.shuffle(_random);
      scales.addAll([_random.nextBool() ? 0.9 : 1.0, 1.3]);
      scales.shuffle(_random);
    } else if (rawChunks.length == 3) {
      alphas.addAll([0.5, 0.75, 1.0]);
      alphas.shuffle(_random);
      scales.addAll([0.8, 1.15, 1.4]);
      scales.shuffle(_random);
    } else {
      final baseAlphas = [0.4, 0.6, 0.8, 1.0];
      final baseScales = [0.8, 1.0, 1.2, 1.4];
      for (int i = 0; i < rawChunks.length; i++) {
        alphas.add(baseAlphas[_random.nextInt(baseAlphas.length)]);
        scales.add(baseScales[_random.nextInt(baseScales.length)]);
      }
    }

    return List.generate(rawChunks.length, (i) {
      final double grayVal = alphas[i];
      final color = Color.fromRGBO(
        (grayVal * 255).round(),
        (grayVal * 255).round(),
        (grayVal * 255).round(),
        1.0,
      );
      return MoodChunk(
        rawChunks[i],
        scales[i],
        1.0, // 固定不透明度 (透明度在后期动画中由组件整体控制)
        delays[i],
        color,
      );
    });
  }
}
