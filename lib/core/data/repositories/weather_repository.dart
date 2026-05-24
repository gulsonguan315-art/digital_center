import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/local_config_store.dart';
import '../models/weather_data.dart';
import '../../log/log.dart';

/// 🌤️ 彩云天气专属数据仓 (Caiyun Weather Repository)
class WeatherRepository {
  final LocalConfigStore _localStore;

  WeatherRepository(this._localStore);

  static late final WeatherRepository instance;

  // 内存缓存
  WeatherData? _cachedData;
  WeatherData? get cachedData => _cachedData;
  
  DateTime? _lastFetchTime;
  bool _isFetching = false;

  final _weatherStreamController = StreamController<WeatherData?>.broadcast();

  /// 数据有效时间 30 分钟 (防刷限流)
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// 系统初始化时预加载本地缓存，实现秒开
  Future<void> init() async {
    final diskCache = await _localStore.weather.readWeatherCache();
    if (diskCache != null) {
      _cachedData = diskCache;
      _lastFetchTime = DateTime.now();
      _weatherStreamController.add(_cachedData);
    }
  }

  /// 手动刷新数据
  Future<WeatherData?> fetchWeather({bool force = false}) async {
    final now = DateTime.now();
    
    if (!force) {
      // 检查内存缓存 (30 分钟内极其新鲜，无需任何 IO)
      if (_cachedData != null && _lastFetchTime != null) {
        if (now.difference(_lastFetchTime!) < _cacheDuration) {
          return _cachedData;
        }
      }
    }

    if (_isFetching) {
      Log.d(LogGroup.network, 'Weather fetch already in progress, returning cached data.');
      return _cachedData;
    }

    _isFetching = true;
    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.weatherBaseUrl; // e.g. https://api.caiyunapp.com/v2.6/TOKEN/LONG,LAT
      if (baseUrl.isEmpty) {
        Log.d(LogGroup.network, 'Weather base URL is empty in api_endpoints.json');
        return null;
      }

      Log.d(LogGroup.network, 'Fetching weather data from Caiyun API...');

      // 一次性获取所有天气数据，避免分三次请求触发免费版的 429 并发限流
      final res = await http.get(Uri.parse('$baseUrl/weather?dailysteps=3&hourlysteps=24')).timeout(const Duration(seconds: 8));
      
      RealtimeWeather? realtime;
      DailyWeather? daily;
      List<HourlyWeather> hourly = [];

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        
        realtime = RealtimeWeather.fromJson(data);
        daily = DailyWeather.fromJson(data);
        
        final hList = data['result']?['hourly']?['temperature'] as List<dynamic>? ?? [];
        final skyList = data['result']?['hourly']?['skycon'] as List<dynamic>? ?? [];
        
        for (int i = 0; i < hList.length; i++) {
          final tempItem = hList[i];
          final skyItem = i < skyList.length ? skyList[i] : {};
          
          hourly.add(HourlyWeather.fromJson({
            'datetime': tempItem['datetime'],
            'value': tempItem['value'],
            'skycon': skyItem['value'],
          }));
        }
      } else {
        Log.d(LogGroup.network, 'Weather API failed: ${res.statusCode} - ${res.body}');
      }

      if (realtime == null || daily == null || hourly.isEmpty) {
        throw Exception('Incomplete weather data (Rate limit or API error).');
      }

      _cachedData = WeatherData(
        realtime: realtime,
        hourly: hourly,
        today: daily,
      );
      _lastFetchTime = now;
      
      // 异步刷入本地磁盘缓存
      _localStore.weather.writeWeatherCache(_cachedData!);

      Log.d(LogGroup.network, 'Successfully refreshed weather data.');
      _weatherStreamController.add(_cachedData);
      return _cachedData;

    } catch (e) {
      Log.d(LogGroup.network, 'Failed to fetch weather data: $e');
      _weatherStreamController.add(_cachedData);
      return _cachedData; // 如果请求失败，返回旧缓存兜底
    } finally {
      _isFetching = false;
    }
  }

  /// 暴露给 DataManager 的流式数据接口
  Stream<WeatherData?> watchWeather() async* {
    if (_cachedData != null) {
      yield _cachedData;
    } else {
      // 初始没有缓存时，尝试去 fetch
      fetchWeather();
    }
    yield* _weatherStreamController.stream;
  }
}
