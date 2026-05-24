/// 🎵 音乐模块本地配置持久化数据模型 (Music Module Local Config)
library;

enum PlaybackMode {
  listLoop,
  singleLoop,
  shuffle,
}

class MusicConfig {
  final List<String> activeFolderIds;
  final PlaybackMode playMode;

  const MusicConfig({
    required this.activeFolderIds,
    required this.playMode,
  });

  factory MusicConfig.fromJson(Map<String, dynamic> json) {
    // 兼容历史数据，若无配置则赋默认值
    final List<dynamic>? folders = json['activeFolderIds'] as List<dynamic>?;
    final int modeIndex = json['playMode'] as int? ?? 0;

    return MusicConfig(
      activeFolderIds: folders?.map((e) => e.toString()).toList() ?? [],
      playMode: PlaybackMode.values.elementAtOrNull(modeIndex) ?? PlaybackMode.listLoop,
    );
  }

  Map<String, dynamic> toJson() => {
        'activeFolderIds': activeFolderIds,
        'playMode': playMode.index,
      };

  static const MusicConfig defaultConfig = MusicConfig(
    activeFolderIds: [],
    playMode: PlaybackMode.listLoop,
  );
}
