import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'music_playback_controller.dart';
import '../../../../core/data/data_manager.dart';
import '../../../../core/data/repositories/music_repository.dart';

/// Top-level function for background isolate JSON parsing
List<List<double>> _parseEqDataInBackground(String content) {
  final List<dynamic> raw = jsonDecode(content);
  return raw.map((frame) => (frame as List).map((e) => (e as num).toDouble()).toList()).toList();
}

/// Keeps the visualizer state local so it does not trigger full-page rebuilds.
class MusicVisualizerController {
  final ValueNotifier<List<double>> heightsNotifier = ValueNotifier<List<double>>(
    List<double>.unmodifiable(List.generate(8, (_) => 0.0)),
  );

  Timer? _visualizerTimer;
  List<List<double>>? _currentEqData;
  String? _loadedTrackId;
  
  List<double> _targetHeights = List.generate(8, (_) => 0.0);
  List<double> _currentHeights = List.generate(8, (_) => 0.0);

  StreamSubscription<String>? _eqSub;

  List<double> get heights => heightsNotifier.value;

  String _makeMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  void startTicker(MusicPlaybackController playback) {
    _visualizerTimer?.cancel();
    _eqSub?.cancel();
    
    _eqSub = MusicRepository.instance.onEqGenerated.listen((cacheKey) {
      final track = playback.currentTrack;
      if (track != null) {
        final currentCacheKey = _makeMd5('${track.path}_${track.size}');
        if (currentCacheKey == cacheKey) {
          final configDirPath = DataManager.instance.configDirPath;
          loadEqData(configDirPath, track.path, track.size);
        }
      }
    });

    // Run at 60fps (~16ms)
    _visualizerTimer = Timer.periodic(const Duration(milliseconds: 16), (_) async {
      final track = playback.currentTrack;
      if (track == null) {
        _setIdleHeights();
        return;
      }

      // Load EQ data if track changed
      if (_loadedTrackId != track.id) {
        _loadedTrackId = track.id;
        _currentEqData = null; // Clear old data immediately
        
        final configDirPath = DataManager.instance.configDirPath;
        loadEqData(configDirPath, track.path, track.size);
      }
      
      if (!playback.isPlaying) {
        _setIdleHeights();
        return;
      }
      
      // Calculate target heights
      if (_currentEqData != null && _currentEqData!.isNotEmpty) {
        final posMs = playback.currentPosition.inMilliseconds;
        final index = posMs ~/ 100; // 10 fps data
        
        if (index >= 0 && index < _currentEqData!.length) {
          final eqFrame = _currentEqData![index];
          for (int i = 0; i < 8; i++) {
            // keep raw 0.0-1.0
            _targetHeights[i] = eqFrame[i];
          }
        }
      } else {
        // Fallback or loading state
        for (int i = 0; i < 8; i++) {
          _targetHeights[i] = (i % 2 == 0 ? 0.3 : 0.5) * (0.3 + 0.7 * (i % 3 == 0 ? 0.8 : 0.4));
        }
      }

      // Lerp current heights towards target heights for smooth spring effect
      bool changed = false;
      for (int i = 0; i < 8; i++) {
        final diff = _targetHeights[i] - _currentHeights[i];
        if (diff.abs() > 0.005) {
          _currentHeights[i] += diff * 0.3; // 0.3 interpolation factor
          changed = true;
        }
      }

      if (changed) {
        heightsNotifier.value = List<double>.unmodifiable(_currentHeights);
      }
    });
  }
  
  void _setIdleHeights() {
    bool changed = false;
    for (int i = 0; i < 8; i++) {
      if (_currentHeights[i] > 0.005) {
        _currentHeights[i] += (0.0 - _currentHeights[i]) * 0.2;
        changed = true;
      } else if (_currentHeights[i] != 0.0) {
        _currentHeights[i] = 0.0;
        changed = true;
      }
    }
    if (changed) {
      heightsNotifier.value = List<double>.unmodifiable(_currentHeights);
    }
  }

  void loadEqData(String configDirPath, String trackPath, int trackSize) async {
      final cacheKey = _makeMd5('${trackPath}_${trackSize}');
      final eqFile = File('$configDirPath/music_cache/eq_$cacheKey.json');
      if (eqFile.existsSync()) {
        try {
          final content = await eqFile.readAsString();
          // Use compute to parse heavy JSON on a background isolate, avoiding UI freezes
          _currentEqData = await compute(_parseEqDataInBackground, content);
        } catch (_) {}
      }
  }

  void dispose() {
    _visualizerTimer?.cancel();
    _eqSub?.cancel();
    heightsNotifier.dispose();
  }
}
