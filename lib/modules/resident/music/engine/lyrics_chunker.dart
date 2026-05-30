import 'dart:math';

/// 情绪歌词切块
class MoodChunk {
  final String text;
  final double scale; // 大小权重，如 0.8, 1.1, 1.4

  MoodChunk(this.text, this.scale);
}

/// 智能断句引擎 (Lyrics Chunker)
class LyricsChunker {
  static final _random = Random();

  /// 将一句歌词切分为最多 3 块情绪碎片
  static List<MoodChunk> chunkLine(String line) {
    if (line.trim().isEmpty) return [];

    // 去除多余空格
    final normalized = line.trim().replaceAll(RegExp(r'\s+'), ' ');
    final containsSpace = normalized.contains(' ');
    List<String> textChunks = [];

    if (containsSpace) {
      // 包含空格的语言（英语、法语、西班牙语、韩语等）
      final words = normalized.split(' ');
      if (words.length <= 3) {
        textChunks = words;
      } else {
        // 单词数大于 3，随机组合成 2~3 个短语块
        int numChunks = _random.nextBool() ? 2 : 3;
        
        if (numChunks == 2) {
          int s = 1 + _random.nextInt(words.length - 1);
          textChunks.add(words.sublist(0, s).join(' '));
          textChunks.add(words.sublist(s).join(' '));
        } else {
          int s1 = 1 + _random.nextInt(words.length - 2);
          int s2 = s1 + 1 + _random.nextInt(words.length - s1 - 1);
          textChunks.add(words.sublist(0, s1).join(' '));
          textChunks.add(words.sublist(s1, s2).join(' '));
          textChunks.add(words.sublist(s2).join(' '));
        }
      }
    } else {
      // 不含空格的语言（中文、日文等）
      if (normalized.length <= 1) {
        textChunks = [normalized];
      } else if (normalized.length == 2) {
        textChunks = [normalized.substring(0, 1), normalized.substring(1, 2)];
      } else if (normalized.length == 3) {
        textChunks = [
          normalized.substring(0, 1),
          normalized.substring(1, 2),
          normalized.substring(2, 3)
        ];
      } else {
        // 长度 >= 4，切割为 2~3 块
        int numChunks = _random.nextBool() ? 2 : 3;
        if (numChunks == 2) {
          int s = 1 + _random.nextInt(normalized.length - 1);
          textChunks.add(normalized.substring(0, s));
          textChunks.add(normalized.substring(s));
        } else {
          int s1 = 1 + _random.nextInt(normalized.length - 2);
          int s2 = s1 + 1 + _random.nextInt(normalized.length - s1 - 1);
          textChunks.add(normalized.substring(0, s1));
          textChunks.add(normalized.substring(s1, s2));
          textChunks.add(normalized.substring(s2));
        }
      }
    }

    // 分配随机大小权重，制造错落美感
    List<double> scales = [];
    if (textChunks.length == 3) {
      scales = [0.8, 1.15, 1.4]; // 小，中，大
      scales.shuffle(_random);
    } else if (textChunks.length == 2) {
      scales = [_random.nextBool() ? 0.9 : 1.0, 1.3];
      scales.shuffle(_random);
    } else {
      scales = [1.2];
    }

    return List.generate(textChunks.length, (i) {
      return MoodChunk(textChunks[i], scales[i]);
    });
  }
}
