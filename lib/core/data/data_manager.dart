import 'dart:async';
import 'dart:io';

import '../log/log.dart';
import 'local/local_config_store.dart';
import 'models/dashboard_item_config.dart';
import 'models/poetry_data.dart';
import 'models/system_settings.dart';
import 'models/music_config.dart';
import 'remote/remote_api_client.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/poetry_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/music_repository.dart';
import 'repositories/weather_repository.dart';
import 'models/weather_data.dart';
import '../engine/audio/app_audio_service.dart';

/// 【数据的总管理员】(Centralized Data Manager - Lightweight Facade)
/// 业务层所有的数据请求、更新、修改均向此管理员发起。
/// 大管家自动协调本地持久化与云端 API。已重构为松耦合分仓代理模式。
class DataManager {
  DataManager._() {
    _localStore = LocalConfigStore();
    _remoteClient = RemoteApiClient();

    // 🚀 绑定底层存储与通信通道，注册全局仓库单例
    PoetryRepository.instance = PoetryRepository(_localStore, _remoteClient);
    SettingsRepository.instance = SettingsRepository(_localStore);
    DashboardRepository.instance = DashboardRepository(_localStore, _remoteClient);
    MusicRepository.instance = MusicRepository(_localStore);
    WeatherRepository.instance = WeatherRepository(_localStore);
  }

  /// 全局唯一单例入口，业务层通过 DataManager.instance 统一访问
  static final DataManager instance = DataManager._();

  late final LocalConfigStore _localStore;
  late final RemoteApiClient _remoteClient;

  LocalConfigStore get localStore => _localStore;

  // 🌟 向下兼容高保真缓存属性
  PoetryData get latestPoetry => PoetryRepository.instance.latestPoetry;
  List<DashboardItemConfig> get latestLayout => DashboardRepository.instance.latestLayout;
  WeatherData? get latestWeather => WeatherRepository.instance.cachedData;

  /// 暴露异步初始化入口，供 main() 显式阻塞等待偏好配置加载（避免冷启动主题闪烁）
  Future<void> init() async {
    // 1. 优先载入系统配置应用给主题/日志引擎
    try {
      await SettingsRepository.instance.restoreSystemSettings();
      
      final settings = await SettingsRepository.instance.getSystemSettings();
      AppAudioService.instance.setVolume(settings.systemVolume);
      
      Timer? volumeDebouncer;
      AppAudioService.instance.addListener(() {
        volumeDebouncer?.cancel();
        volumeDebouncer = Timer(const Duration(milliseconds: 5000), () async {
          final current = await SettingsRepository.instance.getSystemSettings();
          if (current.systemVolume != AppAudioService.instance.volume) {
            SettingsRepository.instance.saveSettings(
              current.copyWith(systemVolume: AppAudioService.instance.volume),
            );
          }
        });
      });
    } catch (_) {}

    // 2. 初始化网络接入终结点配置
    try {
      final endpoints = await _localStore.endpoints.readData();
      _remoteClient.apiBaseUrl = endpoints.poetryBaseUrl;
      
      final String rawPath = '${_localStore.endpoints.configDirPath}/api_endpoints.json';
      final String formattedPath = Platform.isWindows ? rawPath.replaceAll('/', '\\') : rawPath.replaceAll('\\', '/');
      print('🚀 [System] Loaded API endpoints from: $formattedPath | Poetry: ${endpoints.poetryBaseUrl} | Gonic: ${endpoints.gonicBaseUrl}');
      Log.d(LogGroup.network, 'Loaded API endpoints from persistent storage. Path: $formattedPath, Poetry: ${endpoints.poetryBaseUrl}, Gonic: ${endpoints.gonicBaseUrl}');
    } catch (e) {
      print('🚀 [System] Failed to load custom API endpoints. Using defaults.');
      Log.d(LogGroup.network, 'Failed to load custom API endpoints. Using defaults.');
    }

    // 3. 异步引导加载子仓内存缓存
    await PoetryRepository.instance.init();
    await DashboardRepository.instance.init();
    await WeatherRepository.instance.init();
  }

  // ===========================================================================
  // 看板磁贴布局代理 API (Dashboard Layout Proxy API)
  // ===========================================================================

  Stream<List<DashboardItemConfig>> watchDashboardItems() =>
      DashboardRepository.instance.watchDashboardItems();

  Future<void> saveDashboardItems(List<DashboardItemConfig> items) =>
      DashboardRepository.instance.saveDashboardItems(items);

  Future<void> saveDashboardLayout(List<DashboardItemConfig> layoutItems) =>
      DashboardRepository.instance.saveDashboardLayout(layoutItems);

  // ===========================================================================
  // 每日推荐网络古诗词代理 API (Daily Poetry Proxy API)
  // ===========================================================================

  Stream<PoetryData> watchTodayPoetry() =>
      PoetryRepository.instance.watchTodayPoetry();

  Future<void> savePoetryMarks(PoetryData updatedPoetry) =>
      PoetryRepository.instance.savePoetryMarks(updatedPoetry);

  Future<void> saveCustomPoetry(PoetryData updatedPoetry) =>
      PoetryRepository.instance.saveCustomPoetry(updatedPoetry);

  // ===========================================================================
  // 系统设置偏好代理 API (System Settings Proxy API)
  // ===========================================================================

  Future<SystemSettings> getSystemSettings() =>
      SettingsRepository.instance.getSystemSettings();

  Future<void> saveSettings(SystemSettings settings) =>
      SettingsRepository.instance.saveSettings(settings);

  // ===========================================================================
  // 音乐配置偏好代理 API (Music Config Proxy API)
  // ===========================================================================

  Future<MusicConfig> getMusicConfig() =>
      MusicRepository.instance.getMusicConfig();

  Future<void> saveMusicConfig(MusicConfig config) =>
      MusicRepository.instance.saveMusicConfig(config);

  // ===========================================================================
  // 天气预报代理 API (Weather Proxy API)
  // ===========================================================================

  Stream<WeatherData?> watchWeather() =>
      WeatherRepository.instance.watchWeather();

  Future<WeatherData?> fetchWeather({bool force = false}) =>
      WeatherRepository.instance.fetchWeather(force: force);

  bool _isDisposed = false;

  /// 进入后台时，同步刷盘挂起的数据，防止进程被杀导致数据丢失，但不关闭 Stream。
  void flush() {
    _localStore.flush();
  }

  /// 释放大管家持有的底层存储并落锁执行临终同步刷盘
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    MusicRepository.instance.dispose();
    _localStore.dispose();
  }
}
