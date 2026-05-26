import 'package:flutter/foundation.dart';
import '../../../../core/data/repositories/music_repository.dart';
import '../../../../core/data/models/music_data.dart';

/// 📂 独立的播放列表控制器 (Isolated Playlist Controller)
///
/// 专门负责：
/// 1. 加载服务器的根目录 (folders)
/// 2. 维护被勾选的文件夹集合 (activeFolderIds)
/// 3. 获取文件夹下的音频文件，并拼装成合并后的播放列表 (tracks)
class MusicPlaylistController {
  List<MusicFolder> folders = [];
  List<MusicTrack> tracks = [];
  bool isLoadingFolders = true;
  bool isLoadingTracks = false;
  String? errorMessage;

  final Map<String, List<MusicTrack>> _folderTracksMap = {};
  final Set<String> activeFolderIds = {};

  final VoidCallback onUpdate;

  /// 当需要停止当前播放并选定新歌时回调
  final void Function(MusicTrack track) onTrackSelected;

  /// 当播放列表清空时回调
  final VoidCallback onPlaylistEmptied;

  MusicPlaylistController({
    required this.onUpdate,
    required this.onTrackSelected,
    required this.onPlaylistEmptied,
  });

  Future<void> loadFolders(List<String> initialFolderIds, {bool forceRefresh = false}) async {
    isLoadingFolders = true;
    errorMessage = null;
    onUpdate();

    try {
      final alive = await MusicRepository.instance.pingServer();
      if (!alive) throw Exception('无法连通 Gonic 音乐服务，请检查服务器运行状态。');

      final result = await MusicRepository.instance.fetchRootFolders(forceRefresh: forceRefresh);
      folders = result;
      isLoadingFolders = false;

      activeFolderIds.clear();
      activeFolderIds.addAll(initialFolderIds);

      onUpdate();

      if (activeFolderIds.isNotEmpty) {
        isLoadingTracks = true;
        onUpdate();
        for (final id in activeFolderIds) {
          if (!_folderTracksMap.containsKey(id)) {
            final contents = await MusicRepository.instance
                .fetchDirectoryContents(id, forceRefresh: forceRefresh);
            _folderTracksMap[id] =
                contents['tracks'] as List<MusicTrack>? ?? [];
          }
        }
        isLoadingTracks = false;
        _rebuildPlaylist(autoSelectFirst: true);
      } else if (folders.isNotEmpty) {
        await toggleFolder(folders.first.id, forceRefresh: forceRefresh);
      }
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoadingFolders = false;
      onUpdate();
    }
  }

  Future<void> toggleFolder(
    String folderId, {
    VoidCallback? onConfigChange,
    bool forceRefresh = false,
  }) async {
    if (folderId.isEmpty) return;

    if (activeFolderIds.contains(folderId)) {
      activeFolderIds.remove(folderId);
    } else {
      activeFolderIds.add(folderId);
    }

    // 通知外部保存持久化
    onConfigChange?.call();

    isLoadingTracks = true;
    onUpdate();

    try {
      if (!_folderTracksMap.containsKey(folderId)) {
        final contents = await MusicRepository.instance.fetchDirectoryContents(
          folderId,
          forceRefresh: forceRefresh,
        );
        _folderTracksMap[folderId] =
            contents['tracks'] as List<MusicTrack>? ?? [];
      }
      isLoadingTracks = false;
      _rebuildPlaylist(autoSelectFirst: true);
    } catch (_) {
      isLoadingTracks = false;
      onUpdate();
    }
  }

  void _rebuildPlaylist({bool autoSelectFirst = false}) {
    final List<MusicTrack> next = [];
    for (final folder in folders) {
      if (activeFolderIds.contains(folder.id)) {
        final t = _folderTracksMap[folder.id];
        if (t != null) next.addAll(t);
      }
    }
    tracks = next;

    if (tracks.isEmpty) {
      onPlaylistEmptied();
    } else if (autoSelectFirst) {
      // 这里的逻辑可以优化为外部判断，但目前维持原先逻辑：
      // 如果重建列表后发现需要选歌，则选第一首。
      // 这里简略处理，外部（PlaybackController）可以自己决定是否重新选歌。
    }

    onUpdate();
  }

  Future<void> forceRefreshFolders() async {
    _folderTracksMap.clear();
    await loadFolders(activeFolderIds.toList(), forceRefresh: true);
  }
}
