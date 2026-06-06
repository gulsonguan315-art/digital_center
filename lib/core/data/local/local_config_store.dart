import 'dart:io';
import 'package:flutter/foundation.dart';

import 'stores/local_dashboard_store.dart';
import 'stores/local_user_settings_store.dart';
import 'stores/local_music_store.dart';
import 'stores/local_poetry_store.dart';
import 'stores/local_settings_store.dart';
import 'stores/local_weather_store.dart';
import 'stores/local_media_store.dart';
import 'stores/local_media_settings_store.dart';

/// 👑 本地持久化主调度大管家 (Local Config Storage Coordinator)
/// 负责全局数字中心持久化文件夹的初始化，并统一挂载注册所有具体的业务子存储仓。
/// 遵循开闭原则 (OCP)，当新增存储需求时只需创建子仓并在此挂载，无需在此编写具体读写代码。
class LocalConfigStore {
  LocalConfigStore() {
    if (!kIsWeb) {
      _initDirectory();
    }
    dashboard = LocalDashboardStore(configDirPath: configDirPath);
    settings = LocalSettingsStore(configDirPath: configDirPath);
    poetry = LocalPoetryStore(configDirPath: configDirPath); // 📂 注册诗词子仓
    userSettings = LocalUserSettingsStore(
      configDirPath: configDirPath,
    ); // 📂 注册全局用户配置子仓
    music = LocalMusicStore(configDirPath: configDirPath); // 🎵 注册音乐子仓
    weather = LocalWeatherStore(configDirPath: configDirPath); // 🌤️ 注册天气缓存子仓
    media = LocalMediaStore(configDirPath: configDirPath); // 🎬 注册影视元数据缓存子仓
    mediaSettings = LocalMediaSettingsStore(configDirPath: configDirPath); // ⚙️ 影视设置持久化
  }

  /// 📂 看板卡片排版专属子仓
  late final LocalDashboardStore dashboard;

  /// 📂 系统偏好与日志白名单专属子仓
  late final LocalSettingsStore settings;

  /// 📂 每日网络诗词专属子仓
  late final LocalPoetryStore poetry;

  /// 📂 全局用户配置子仓
  late final LocalUserSettingsStore userSettings;

  /// 🎵 音乐模块播放状态和选中目录专属子仓
  late final LocalMusicStore music;

  /// 🌤️ 气象数据专属子仓
  late final LocalWeatherStore weather;

  /// 🎬 影视元数据缓存子仓
  late final LocalMediaStore media;

  /// ⚙️ 影视播放配置存储
  late final LocalMediaSettingsStore mediaSettings;

  /// 获取系统 AppData 存储路径
  String get configDirPath {
    if (kIsWeb) return '';
    final String appData =
        Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
    return '$appData/digital_center';
  }

  /// 检查并安全初始化本地存储主目录
  void _initDirectory() {
    if (kIsWeb) return;
    try {
      final dir = Directory(configDirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final musicCacheDir = Directory('$configDirPath/music_cache');
      if (!musicCacheDir.existsSync()) {
        musicCacheDir.createSync(recursive: true);
      }
      final musicSubDir = Directory('$configDirPath/music_cache/music');
      if (!musicSubDir.existsSync()) {
        musicSubDir.createSync(recursive: true);
      }
    } catch (e) {
      // 容错防御：静默拦截系统级 I/O 权限异常
    }
  }

  /// 仅执行后台挂起前的同步数据刷盘，但不关闭底层事件流
  void flush() {
    dashboard.flush();
  }

  /// 安全释放全局防抖计时器并落锁执行各子仓的关机同步刷盘
  void dispose() {
    dashboard.dispose();
    poetry.dispose();
    music.dispose();
  }
}
