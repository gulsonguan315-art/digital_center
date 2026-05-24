import 'dart:io';
import 'package:flutter/foundation.dart';

import 'stores/local_dashboard_store.dart';
import 'stores/local_endpoints_store.dart';
import 'stores/local_music_store.dart';
import 'stores/local_poetry_store.dart';
import 'stores/local_settings_store.dart';

/// 👑 本地持久化主调度大管家 (Local Config Storage Coordinator)
/// 负责全局数字中心持久化文件夹的初始化，并统一挂载注册所有具体的业务子存储仓。
/// 遵循开闭原则 (OCP)，当新增存储需求时只需创建子仓并在此挂载，无需在此编写具体读写代码。
class LocalConfigStore {
  LocalConfigStore() {
    if (!kIsWeb) {
      _initDirectory();
    }
    dashboard = LocalDashboardStore(configDirPath: _configDirPath);
    settings = LocalSettingsStore(configDirPath: _configDirPath);
    poetry = LocalPoetryStore(configDirPath: _configDirPath); // 📂 注册诗词子仓
    endpoints = LocalEndpointsStore(configDirPath: _configDirPath); // 📂 注册全局 API 终端子仓
    music = LocalMusicStore(configDirPath: _configDirPath); // 🎵 注册音乐子仓
  }

  /// 📂 看板卡片排版专属子仓
  late final LocalDashboardStore dashboard;

  /// 📂 系统偏好与日志白名单专属子仓
  late final LocalSettingsStore settings;

  /// 📂 每日网络诗词专属子仓
  late final LocalPoetryStore poetry;

  /// 📂 全局 API 接口终端配置专属子仓
  late final LocalEndpointsStore endpoints;

  /// 🎵 音乐模块播放状态和选中目录专属子仓
  late final LocalMusicStore music;

  /// 获取系统 AppData 存储路径
  String get _configDirPath {
    if (kIsWeb) return '';
    final String appData = Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
    return '$appData/digital_center';
  }

  /// 检查并安全初始化本地存储主目录
  void _initDirectory() {
    if (kIsWeb) return;
    try {
      final dir = Directory(_configDirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    } catch (e) {
      // 容错防御：静默拦截系统级 I/O 权限异常
    }
  }

  /// 安全释放全局防抖计时器并落锁执行各子仓的关机同步刷盘
  void dispose() {
    dashboard.dispose();
    poetry.dispose();
    music.dispose();
  }
}
