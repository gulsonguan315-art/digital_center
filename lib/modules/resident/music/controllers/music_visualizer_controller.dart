import 'dart:async';
import 'package:flutter/foundation.dart';

/// 🌊 独立的可视化均衡器控制器 (Isolated Visualizer Controller)
///
/// 专门负责维持 Ticker 定时器计算 8 根柱子的随机跳动算法。
class MusicVisualizerController {
  final List<double> heights = List.generate(8, (_) => 4.0);
  Timer? _visualizerTimer;

  final VoidCallback onUpdate;

  MusicVisualizerController({required this.onUpdate});

  void startTicker(bool Function() isPlayingCheck) {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (isPlayingCheck()) {
        for (int i = 0; i < heights.length; i++) {
          heights[i] =
              4.0 + (i % 2 == 0 ? 16.0 : 24.0) * (0.3 + 0.7 * (i % 3 == 0 ? 0.8 : 0.4));
        }
      } else {
        heights.fillRange(0, heights.length, 4.0);
      }
      onUpdate();
    });
  }

  void dispose() {
    _visualizerTimer?.cancel();
  }
}
