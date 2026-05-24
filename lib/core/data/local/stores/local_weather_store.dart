import 'dart:convert';
import 'dart:io';
import '../../models/weather_data.dart';
import '../../../log/log.dart';

/// 🌤️ 气象数据专属子仓 (Dedicated Weather Store)
/// 负责将大请求量的天气预报序列化落盘，防止 API 超额。
class LocalWeatherStore {
  final String configDirPath;

  LocalWeatherStore({required this.configDirPath});

  String get _filePath => '$configDirPath/weather_cache.json';

  Future<WeatherData?> readWeatherCache() async {
    try {
      final file = File(_filePath);
      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      if (content.isEmpty) return null;

      final json = jsonDecode(content) as Map<String, dynamic>;
      
      // 检查缓存时间 (从文件修改时间判断)
      final lastModified = await file.lastModified();
      final age = DateTime.now().difference(lastModified);
      
      if (age > const Duration(hours: 6)) {
        Log.d(LogGroup.system, 'Local weather cache expired (age: ${age.inHours}h), needs refresh.');
        return null; // 过期返回 null，要求外部重新抓取
      }

      Log.d(LogGroup.system, 'Loaded weather data from local cache (age: ${age.inMinutes}m).');
      return WeatherData.fromJson(json);
    } catch (e) {
      Log.d(LogGroup.system, 'Failed to read weather cache: $e');
      return null;
    }
  }

  Future<void> writeWeatherCache(WeatherData data) async {
    try {
      final file = File(_filePath);
      final encoded = jsonEncode(data.toJson());
      await file.writeAsString(encoded, flush: true);
    } catch (e) {
      Log.d(LogGroup.system, 'Failed to write weather cache: $e');
    }
  }
}
