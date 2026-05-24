import 'package:flutter/material.dart';

import '../../../core/data/models/music_data.dart';
import '../../../core/data/models/music_config.dart';
import '../../../core/data/data_manager.dart';

import 'music_service.dart';

/// 🎛️ 音乐页面总代调层 (Music Callback Facade)
///
/// 作为 UI 组件和全局音乐服务 [MusicService] 的桥梁。
/// 它的生命周期由 UI 控制，但绝不会销毁音乐引擎。
class MusicCallback extends ChangeNotifier {
  MusicService get service => MusicService.instance;

  MusicCallback() {
    // 监听全局服务，触发 UI 刷新
    service.addListener(notifyListeners);

    // 初始加载逻辑
    if (service.playlist.folders.isEmpty) {
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    List<String> initialFolders = [];
    try {
      final config = await DataManager.instance.getMusicConfig();
      initialFolders = config.activeFolderIds;
      service.playback.playMode = config.playMode;
    } catch (_) {
      // 忽略
    }
    
    await service.playlist.loadFolders(initialFolders);
    service.playback.handlePlaylistRebuilt();
  }

  // ===========================================================================
  // 🔌 对外代理 API (Facade APIs for UI)
  // ===========================================================================

  void toggleFolder(String folderId) {
    service.playlist.toggleFolder(folderId, onConfigChange: _saveConfig);
    service.playback.handlePlaylistRebuilt();
  }

  void selectTrack(MusicTrack track) => service.playback.selectTrack(track);

  void togglePlayPause() => service.playback.togglePlayPause();

  void playPrevTrack() => service.playback.playPrevTrack();

  void playNextTrack() => service.playback.playNextTrack();

  void togglePlayMode() {
    final nextIndex = (service.playback.playMode.index + 1) % PlaybackMode.values.length;
    service.playback.playMode = PlaybackMode.values[nextIndex];
    _saveConfig();
    notifyListeners();
  }

  void seekTo(Duration position) => service.playback.seekTo(position);

  void retryLoadFolders() => _loadInitialData();

  // ===========================================================================
  // 💾 状态持久化
  // ===========================================================================

  void _saveConfig() {
    DataManager.instance.saveMusicConfig(
      MusicConfig(
        activeFolderIds: service.playlist.activeFolderIds.toList(),
        playMode: service.playback.playMode,
      ),
    );
  }

  @override
  void dispose() {
    // 仅仅解除绑定，不销毁全局 Service
    service.removeListener(notifyListeners);
    super.dispose();
  }
}
