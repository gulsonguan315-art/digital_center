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
  final int immersiveStyleIndex;
  final String? lastPlayingTrackId;

  const MusicConfig({
    required this.activeFolderIds,
    required this.playMode,
    required this.immersiveStyleIndex,
    this.lastPlayingTrackId,
  });

  factory MusicConfig.fromJson(Map<String, dynamic> json) {
    // 兼容历史数据，若无配置则赋默认值
    final List<dynamic>? folders = json['activeFolderIds'] as List<dynamic>?;
    final int modeIndex = json['playMode'] as int? ?? 0;
    final int styleIndex = json['immersiveStyleIndex'] as int? ?? 0;
    final String? lastTrack = json['lastPlayingTrackId'] as String?;

    return MusicConfig(
      activeFolderIds: folders?.map((e) => e.toString()).toList() ?? [],
      playMode: PlaybackMode.values.elementAtOrNull(modeIndex) ?? PlaybackMode.listLoop,
      immersiveStyleIndex: styleIndex,
      lastPlayingTrackId: lastTrack,
    );
  }

  Map<String, dynamic> toJson() => {
        'activeFolderIds': activeFolderIds,
        'playMode': playMode.index,
        'immersiveStyleIndex': immersiveStyleIndex,
        if (lastPlayingTrackId != null) 'lastPlayingTrackId': lastPlayingTrackId,
      };

  static const MusicConfig defaultConfig = MusicConfig(
    activeFolderIds: [],
    playMode: PlaybackMode.listLoop,
    immersiveStyleIndex: 0,
    lastPlayingTrackId: null,
  );

  MusicConfig copyWith({
    List<String>? activeFolderIds,
    PlaybackMode? playMode,
    int? immersiveStyleIndex,
    String? lastPlayingTrackId,
  }) {
    return MusicConfig(
      activeFolderIds: activeFolderIds ?? this.activeFolderIds,
      playMode: playMode ?? this.playMode,
      immersiveStyleIndex: immersiveStyleIndex ?? this.immersiveStyleIndex,
      lastPlayingTrackId: lastPlayingTrackId ?? this.lastPlayingTrackId,
    );
  }
}
