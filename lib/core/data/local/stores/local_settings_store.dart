import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../models/system_settings.dart';

/// Top-level settings serialization helper for background Isolate execution.
String _encodeSettings(SystemSettings settings) {
  return jsonEncode(settings.toJson());
}

/// Top-level settings deserialization helper for background Isolate execution.
SystemSettings _decodeSettings(String content) {
  return SystemSettings.fromJson(jsonDecode(content) as Map<String, dynamic>);
}

/// 📂 系统设置偏好专属子仓 (Dedicated Settings Sub-store)
/// 独立负责系统偏好配置（亮暗模式、视觉特效、直角形状、日志组开关）的数据持久化。
class LocalSettingsStore {
  final String configDirPath;

  LocalSettingsStore({required this.configDirPath});

  String get _settingsFilePath => '$configDirPath/system_settings.json';

  /// Reads system settings from disk. Offloads decoding to a background Isolate.
  Future<SystemSettings> readSystemSettings() async {
    if (kIsWeb) {
      return SystemSettings.defaultSettings;
    }
    try {
      final file = File(_settingsFilePath);
      if (!file.existsSync()) {
        return SystemSettings.defaultSettings;
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return SystemSettings.defaultSettings;
      }
      // 🚀 Isolate-based JSON decoding
      return await compute(_decodeSettings, content);
    } catch (e) {
      return SystemSettings.defaultSettings;
    }
  }

  /// Writes system settings to disk. Offloads encoding to a background Isolate.
  Future<void> writeSystemSettings(SystemSettings settings) async {
    if (kIsWeb) return;
    try {
      final file = File(_settingsFilePath);
      // 🚀 Isolate-based JSON encoding
      final encoded = await compute(_encodeSettings, settings);
      await file.writeAsString(encoded, flush: true);
    } catch (e) {
      // Silent catch
    }
  }
}
