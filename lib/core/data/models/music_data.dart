/// 🎵 多媒体音乐数据模型 (Gonic Subsonic Music Data Models)
/// 统一管理物理文件夹、歌曲元数据以及播放列表。
library;

/// 📁 物理文件夹/目录实体 (Physical Folder / Directory Entity)
class MusicFolder {
  final String id;
  final String name;
  final bool isDir;

  const MusicFolder({required this.id, required this.name, this.isDir = true});

  factory MusicFolder.fromJson(Map<String, dynamic> json) {
    return MusicFolder(
      id: json['id'] as String? ?? '',
      name:
          json['title'] as String? ??
          json['name'] as String? ??
          'Unknown Folder',
      isDir: json['isDir'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isDir': isDir};
}

/// 🎶 歌曲文件元数据实体 (Audio File / Song Metadata Entity)
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int duration; // 时长（秒）
  final int size; // 文件大小（字节）
  final String path; // 物理相对路径
  final String? coverArtId; // 专辑插图/封面 ID

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.size,
    required this.path,
    this.coverArtId,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as String? ?? '',
      title:
          json['title'] as String? ??
          json['name'] as String? ??
          'Unknown Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String? ?? 'Unknown Album',
      duration: (json['duration'] is num)
          ? (json['duration'] as num).toInt()
          : 0,
      size: (json['size'] is num) ? (json['size'] as num).toInt() : 0,
      path: json['path'] as String? ?? '',
      coverArtId: json['coverArt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'duration': duration,
    'size': size,
    'path': path,
    'coverArt': coverArtId,
  };

  /// 格式化为 MM:SS 风格的时间显示
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化为 MB 风格的文件大小显示
  String get formattedSize {
    final mb = size / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
