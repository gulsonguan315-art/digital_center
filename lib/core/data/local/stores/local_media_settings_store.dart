import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 影视播放设置（倍速、跳过片头片尾）本地磁盘存储
class LocalMediaSettingsStore {
  final String configDirPath;
  Map<String, Map<String, dynamic>> _cache = {};
  bool _isLoaded = false;

  LocalMediaSettingsStore({required this.configDirPath});

  String get _cacheDirPath => '$configDirPath/media_cache';
  String get _filePath => '$_cacheDirPath/media_settings.json';

  Future<void> _ensureCacheDir() async {
    if (kIsWeb) return;
    final dir = Directory(_cacheDirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }

  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;
    if (kIsWeb) return;
    try {
      final file = File(_filePath);
      if (file.existsSync()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          _cache = decoded.map((key, value) => MapEntry(key, value as Map<String, dynamic>));
        }
      }
    } catch (_) {}
    _isLoaded = true;
  }

  Future<void> _save() async {
    if (kIsWeb) return;
    try {
      await _ensureCacheDir();
      final file = File(_filePath);
      await file.writeAsString(jsonEncode(_cache), flush: true);
    } catch (_) {}
  }

  Map<String, dynamic> _getSettings(String seriesId) {
    return _cache[seriesId] ?? <String, dynamic>{};
  }

  Future<double> getSpeed(String seriesId) async {
    await _ensureLoaded();
    return (_getSettings(seriesId)['speed'] as num?)?.toDouble() ?? 1.0;
  }

  Future<void> setSpeed(String seriesId, double speed) async {
    await _ensureLoaded();
    final settings = _getSettings(seriesId);
    settings['speed'] = speed;
    _cache[seriesId] = settings;
    await _save();
  }

  Future<bool> getAutoSkip(String seriesId) async {
    await _ensureLoaded();
    return _getSettings(seriesId)['auto_skip'] as bool? ?? false;
  }

  Future<void> setAutoSkip(String seriesId, bool autoSkip) async {
    await _ensureLoaded();
    final settings = _getSettings(seriesId);
    settings['auto_skip'] = autoSkip;
    _cache[seriesId] = settings;
    await _save();
  }

  Future<int> getIntroDuration(String seriesId) async {
    await _ensureLoaded();
    return _getSettings(seriesId)['intro_duration'] as int? ?? 0;
  }

  Future<void> setIntroDuration(String seriesId, int durationMs) async {
    await _ensureLoaded();
    final settings = _getSettings(seriesId);
    settings['intro_duration'] = durationMs;
    _cache[seriesId] = settings;
    await _save();
  }

  Future<int> getOutroDuration(String seriesId) async {
    await _ensureLoaded();
    return _getSettings(seriesId)['outro_duration'] as int? ?? 0;
  }

  Future<void> setOutroDuration(String seriesId, int durationMs) async {
    await _ensureLoaded();
    final settings = _getSettings(seriesId);
    settings['outro_duration'] = durationMs;
    _cache[seriesId] = settings;
    await _save();
  }
}
