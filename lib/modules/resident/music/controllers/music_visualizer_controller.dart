import 'dart:async';
import 'package:flutter/foundation.dart';

/// Keeps the visualizer state local so it does not trigger full-page rebuilds.
class MusicVisualizerController {
  final ValueNotifier<List<double>> heightsNotifier = ValueNotifier<List<double>>(
    List<double>.unmodifiable(List.generate(8, (_) => 4.0)),
  );

  Timer? _visualizerTimer;

  List<double> get heights => heightsNotifier.value;

  void startTicker(bool Function() isPlayingCheck) {
    _visualizerTimer?.cancel();
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      final nextHeights = List<double>.generate(8, (i) {
        if (!isPlayingCheck()) return 4.0;
        return 4.0 + (i % 2 == 0 ? 16.0 : 24.0) * (0.3 + 0.7 * (i % 3 == 0 ? 0.8 : 0.4));
      });

      if (!listEquals(nextHeights, heightsNotifier.value)) {
        heightsNotifier.value = List<double>.unmodifiable(nextHeights);
      }
    });
  }

  void dispose() {
    _visualizerTimer?.cancel();
    heightsNotifier.dispose();
  }
}
