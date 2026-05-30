import 'dart:math';

class MoodChunk {
  final String text;
  final double scale; // 大小权重，如 0.8, 1.1, 1.4
  final double alpha; // 透明度权重，如 0.5, 1.0

  MoodChunk(this.text, this.scale, this.alpha);
}

class LyricsChunker {
  static final _random = Random();

  static List<MoodChunk> chunkLine(String line) {
    if (line.trim().isEmpty) return [];

    final chunks = line
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (chunks.isEmpty) return [];
    if (chunks.length == 1) return [MoodChunk(chunks[0], 1.2, 1.0)];

    // 生成固定但错落的字号权重和透明度权重
    final List<double> scales = [];
    final List<double> alphas = [];
    if (chunks.length == 2) {
      scales.addAll([_random.nextBool() ? 0.9 : 1.0, 1.3]);
      alphas.addAll([0.5, 1.0]);

      scales.shuffle(_random);
      alphas.shuffle(_random);
    } else if (chunks.length == 3) {
      scales.addAll([0.8, 1.15, 1.4]);
      alphas.addAll([0.3, 0.7, 1.0]);

      scales.shuffle(_random);
      alphas.shuffle(_random);
    } else {
      // 如果块大于3个，随机分配不同大小
      final baseScales = [0.8, 1.0, 1.2, 1.4];
      final baseAlphas = [0.4, 0.6, 0.8, 1.0];
      for (int i = 0; i < chunks.length; i++) {
        scales.add(baseScales[_random.nextInt(baseScales.length)]);
        alphas.add(baseAlphas[_random.nextInt(baseAlphas.length)]);
      }
    }

    return List.generate(chunks.length, (i) {
      return MoodChunk(chunks[i], scales[i], alphas[i]);
    });
  }
}
