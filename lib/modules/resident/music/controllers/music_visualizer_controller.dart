import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'music_playback_controller.dart';
import '../../../../core/data/data_manager.dart';
import '../../../../core/data/repositories/music_cache_manager.dart';

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
  
  final List<double> _targetHeights = List.generate(8, (_) => 0.0);
  final List<double> _currentHeights = List.generate(8, (_) => 0.0);

  StreamSubscription<String>? _eqSub;

  // 60FPS 极速平滑音频-视觉同步系统
  double _smoothPosMs = 0.0;
  DateTime? _lastTickTime;
  static const int _latencyCompensationMs = 150; // 音频设备输出缓冲延迟补偿 (150ms)

  List<double> get heights => heightsNotifier.value;

  String _makeMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  void startTicker(MusicPlaybackController playback) {
    _visualizerTimer?.cancel();
    _eqSub?.cancel();
    
    _smoothPosMs = 0.0;
    _lastTickTime = null;
    
    _eqSub = MusicCacheManager.instance.onEqGenerated.listen((cacheKey) {
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
        _lastTickTime = null;
        return;
      }

      // Load EQ data if track changed
      if (_loadedTrackId != track.id) {
        _loadedTrackId = track.id;
        _currentEqData = null; // Clear old data immediately
        _smoothPosMs = 0.0;
        _lastTickTime = null;
        
        final configDirPath = DataManager.instance.configDirPath;
        loadEqData(configDirPath, track.path, track.size);
      }
      
      if (!playback.isPlaying) {
        _setIdleHeights();
        _lastTickTime = null;
        return;
      }
      
      // Calculate elapsed dt in milliseconds
      final now = DateTime.now();
      final double dt = _lastTickTime == null
          ? 16.0
          : now.difference(_lastTickTime!).inMicroseconds / 1000.0;
      _lastTickTime = now;

      // Calculate target heights
      if (_currentEqData != null && _currentEqData!.isNotEmpty) {
        final double actualPosMs = playback.currentPosition.inMilliseconds.toDouble();
        
        // 软同步平滑位置以防突变/跳帧
        if ((_smoothPosMs - actualPosMs).abs() > 300.0) {
          // 如果偏差大于300ms（例如用户seek或换歌），立即强行校正同步
          _smoothPosMs = actualPosMs;
        } else {
          // 否则随时间正常自然递增，并微调进行偏差收敛
          _smoothPosMs += dt;
          _smoothPosMs += (actualPosMs - _smoothPosMs) * 0.1;
        }

        // 应用设备输出的延迟补偿偏移量，对齐人耳听觉
        final double compensatedPos = _smoothPosMs - _latencyCompensationMs;
        final int index = compensatedPos.toInt() ~/ 100; // 10 fps data (每100ms一帧)
        
        if (index >= 0 && index < _currentEqData!.length) {
          final eqFrame = _currentEqData![index];
          for (int i = 0; i < 8; i++) {
            _targetHeights[i] = eqFrame[i];
          }
        }
      } else {
        // 过程化动态平滑呼吸兜底 (Smooth Ambient Procedural Fallback)
        // 在线播放或加载期间，使用极其平滑的低频正弦波让频谱呈现出“温和呼吸”的氛围感。
        // 由于没有任何瞬间跳变差分，这绝不会误触发任何涟漪发射，直到真实的 EQ 数据加载完毕！
        final double timeSec = now.millisecondsSinceEpoch / 1000.0;
        for (int i = 0; i < 8; i++) {
          final double speed = 1.5 + (i * 0.3);
          final double wave = sin(timeSec * speed) * 0.15 + cos(timeSec * (speed * 0.7)) * 0.05;
          _targetHeights[i] = 0.15 + wave.abs();
          _targetHeights[i] = _targetHeights[i].clamp(0.0, 1.0);
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
      final normalizedPath = trackPath.replaceAll('/', Platform.pathSeparator).replaceAll('\\', Platform.pathSeparator);
      final eqFile = File('$configDirPath/music_cache/music/$normalizedPath.eq.json');
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
