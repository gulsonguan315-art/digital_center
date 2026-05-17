import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../models/poetry_data.dart';

/// Top-level settings serialization helper for background Isolate execution.
String _encodePoetry(PoetryData poetry) {
  return jsonEncode(poetry.toJson());
}

/// Top-level settings deserialization helper for background Isolate execution.
PoetryData _decodePoetry(String content) {
  return PoetryData.fromJson(jsonDecode(content) as Map<String, dynamic>);
}

/// 📂 每日网络诗词专属子仓 (Dedicated Poetry Sub-store)
/// 独立负责今日推荐诗词的本地持久化读取与写入，防止网络异常导致页面白屏。
class LocalPoetryStore {
  final String configDirPath;

  LocalPoetryStore({required this.configDirPath});

  final _poetryController = StreamController<PoetryData>.broadcast();

  String get _filePath => '$configDirPath/daily_poetry.json';

  /// Exposes a responsive stream monitoring local poetry data updates.
  Stream<PoetryData> watchPoetry() => _poetryController.stream;

  /// Reads today's cached poetry from the disk. Offloads decoding to a background Isolate.
  Future<PoetryData> readPoetry() async {
    if (kIsWeb) {
      return PoetryData.defaultPoetry;
    }
    try {
      final file = File(_filePath);
      if (!file.existsSync()) {
        return PoetryData.defaultPoetry;
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return PoetryData.defaultPoetry;
      }
      // 🚀 Isolate-based JSON decoding
      return await compute(_decodePoetry, content);
    } catch (e) {
      return PoetryData.defaultPoetry;
    }
  }

  /// Writes poetry data to disk. Offloads encoding to a background Isolate.
  Future<void> writePoetry(PoetryData poetry) async {
    if (kIsWeb) {
      _poetryController.add(poetry);
      return;
    }
    try {
      final file = File(_filePath);
      // 🚀 Isolate-based JSON encoding
      final encoded = await compute(_encodePoetry, poetry);
      await file.writeAsString(encoded, flush: true);
      _poetryController.add(poetry); // Emit update to reactive listeners
    } catch (e) {
      // Silent catch
    }
  }

  /// Safe dispose.
  void dispose() {
    _poetryController.close();
  }
}
