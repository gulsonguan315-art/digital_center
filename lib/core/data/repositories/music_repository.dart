import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../local/local_config_store.dart';
import '../models/api_endpoints.dart';
import '../models/music_data.dart';
import '../models/music_config.dart';
import '../../log/log.dart';

/// 📂 Gonic Subsonic 音乐服务专属数据仓 (Gonic Music Domain Repository)
/// 负责处理 Gonic Subsonic 协议下的安全鉴权、物理文件夹遍历、音频流直链生成及 LRC 动态歌词拉取。
class MusicRepository {
  final LocalConfigStore _localStore;

  MusicRepository(this._localStore);

  bool _isDisposed = false;

  /// 释放资源
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _cacheNotifier.close();
    _downloadingCacheKeys.clear();
  }

  /// 跟踪正在后台下载的音频缓存 Key
  final Set<String> _downloadingCacheKeys = {};


  /// 广播缓存完成事件通知，String 为 track.id
  final _cacheNotifier = StreamController<String>.broadcast();
  Stream<String> get onTrackCached => _cacheNotifier.stream;

  /// 全局唯一单例，由 DataManager 在初始化时注入绑定
  static late final MusicRepository instance;

  /// 用于微秒级随机数计算生成 Salt
  String _generateSalt() {
    final rand = Random();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(10, (i) => chars[rand.nextInt(chars.length)]).join();
  }

  /// 计算 Subsonic 标准 MD5 签名：`Hex(MD5(password + salt))`
  String _makeMd5(String text) {
    return md5.convert(utf8.encode(text)).toString();
  }

  /// 🔐 动态构建安全的 Subsonic 鉴权查询字符串 (Secure MD5 Auth Parameters)
  Future<String> _buildAuthParams(ApiEndpoints endpoints) async {
    final u = endpoints.gonicUsername;
    final p = endpoints.gonicPassword;
    final salt = _generateSalt();
    final token = _makeMd5(p + salt);
    return 'u=$u&t=$token&s=$salt&v=1.15.0&c=superfocus_app&f=json';
  }

  /// 🎵 本地持久化代理接口 (Local Persistence Proxy)
  Future<MusicConfig> getMusicConfig() => _localStore.music.readConfig();
  Future<void> saveMusicConfig(MusicConfig config) =>
      _localStore.music.writeConfig(config);

  /// 📡 1. 验证 Gonic 服务器的连通性与账号密码正确性 (Ping Connection)
  Future<bool> pingServer() async {
    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return false;

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/ping.view?$authParams';

      Log.d(LogGroup.network, 'Pinging Gonic server at: $baseUrl');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse =
            data['subsonic-response'] as Map<String, dynamic>? ?? {};
        final status = subsonicResponse['status'] as String? ?? 'failed';

        Log.d(LogGroup.network, 'Gonic ping status: $status');
        return status == 'ok';
      }
      return false;
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to ping Gonic server: $e');
      return false;
    }
  }

  /// 📁 检查本地是否存在根文件夹的缓存文件
  bool hasCachedRootFolders() {
    final cacheFile = File(
      '${_localStore.configDirPath}/music_cache/root_folders.json',
    );
    return cacheFile.existsSync();
  }

  /// 📁 2. 获取 6 个物理词牌名根文件夹列表 (Fetch Physical Root Folders)

  /// 在 Gonic 优异的映射逻辑中，`getIndexes.view` 会将第一级子目录作为 Index/Artist 实体完美返回。
  Future<List<MusicFolder>> fetchRootFolders({
    bool forceRefresh = false,
  }) async {
    final List<MusicFolder> folders = [];
    final cacheFile = File(
      '${_localStore.configDirPath}/music_cache/root_folders.json',
    );

    if (!forceRefresh && cacheFile.existsSync()) {
      try {
        final content = await cacheFile.readAsString();
        final data = jsonDecode(content) as List<dynamic>;
        for (var item in data) {
          folders.add(MusicFolder.fromJson(item as Map<String, dynamic>));
        }
        Log.d(
          LogGroup.network,
          'Loaded ${folders.length} root folders from cache',
        );
        return folders;
      } catch (e) {
        Log.d(LogGroup.network, 'Failed to load root folders from cache: $e');
      }
    }
    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return folders;

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/getIndexes.view?$authParams';

      Log.d(LogGroup.network, 'Fetching physical root folders from Gonic');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse =
            data['subsonic-response'] as Map<String, dynamic>? ?? {};
        final indexes =
            subsonicResponse['indexes'] as Map<String, dynamic>? ?? {};
        final indexList = indexes['index'] as List<dynamic>? ?? [];

        for (var idx in indexList) {
          final artists = idx['artist'];
          if (artists is List) {
            for (var artist in artists) {
              folders.add(MusicFolder.fromJson(artist as Map<String, dynamic>));
            }
          } else if (artists is Map) {
            folders.add(MusicFolder.fromJson(artists as Map<String, dynamic>));
          }
        }

        Log.d(
          LogGroup.network,
          'Successfully parsed ${folders.length} root poetry folders from Gonic',
        );

        try {
          final cacheData = folders.map((f) => f.toJson()).toList();
          await cacheFile.writeAsString(jsonEncode(cacheData));
        } catch (e) {
          Log.d(LogGroup.network, 'Failed to write root folders cache: $e');
        }
      }
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to fetch root folders from Gonic: $e');
    }
    return folders;
  }

  /// 🗂️ 3. 物理遍历指定目录内的歌曲与子文件夹 (Fetch Directory Contents)
  /// 根据物理目录的 ID 展开子目录与音频歌曲列表。
  Future<Map<String, dynamic>> fetchDirectoryContents(
    String folderId, {
    bool forceRefresh = false,
  }) async {
    final List<MusicFolder> subFolders = [];
    final List<MusicTrack> tracks = [];
    final cacheFile = File(
      '${_localStore.configDirPath}/music_cache/dir_$folderId.json',
    );

    if (!forceRefresh && cacheFile.existsSync()) {
      try {
        final content = await cacheFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final cachedFolders = data['folders'] as List<dynamic>? ?? [];
        final cachedTracks = data['tracks'] as List<dynamic>? ?? [];

        subFolders.addAll(
          cachedFolders.map(
            (e) => MusicFolder.fromJson(e as Map<String, dynamic>),
          ),
        );
        tracks.addAll(
          cachedTracks.map(
            (e) => MusicTrack.fromJson(e as Map<String, dynamic>),
          ),
        );

        Log.d(
          LogGroup.network,
          'Loaded directory contents for ID: $folderId from cache',
        );
        return {'folders': subFolders, 'tracks': tracks};
      } catch (e) {
        Log.d(
          LogGroup.network,
          'Failed to load directory cache for ID: $folderId: $e',
        );
      }
    }

    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) {
        return {'folders': subFolders, 'tracks': tracks};
      }

      final authParams = await _buildAuthParams(endpoints);
      final url =
          '$baseUrl/rest/getMusicDirectory.view?$authParams&id=$folderId';

      Log.d(LogGroup.network, 'Fetching directory contents for ID: $folderId');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse =
            data['subsonic-response'] as Map<String, dynamic>? ?? {};
        final directory =
            subsonicResponse['directory'] as Map<String, dynamic>? ?? {};
        final children = directory['child'] as List<dynamic>? ?? [];

        for (var child in children) {
          final childMap = child as Map<String, dynamic>;
          final isDir = childMap['isDir'] as bool? ?? false;
          if (isDir) {
            subFolders.add(MusicFolder.fromJson(childMap));
          } else {
            tracks.add(MusicTrack.fromJson(childMap));
          }
        }
        Log.d(
          LogGroup.network,
          'Directory contents parsed: ${subFolders.length} subfolders, ${tracks.length} tracks',
        );

        try {
          final cacheData = {
            'folders': subFolders.map((f) => f.toJson()).toList(),
            'tracks': tracks.map((t) => t.toJson()).toList(),
          };
          await cacheFile.writeAsString(jsonEncode(cacheData));
        } catch (e) {
          Log.d(
            LogGroup.network,
            'Failed to write directory cache for ID: $folderId: $e',
          );
        }
      }
    } catch (e) {
      Log.d(
        LogGroup.network,
        'Failed to fetch directory contents for ID: $folderId: $e',
      );
    }

    return {'folders': subFolders, 'tracks': tracks};
  }

  /// 🔍 检查某首歌曲是否已经下载缓存到本地
  bool isTrackCached(MusicTrack track) {
    try {
      final cacheKey = _makeMd5('${track.path}_${track.size}');
      final cacheFile = File(
        '${_localStore.configDirPath}/music_cache/audio_$cacheKey.dat',
      );
      return cacheFile.existsSync();
    } catch (e) {
      return false;
    }
  }

  Future<String> getAudioPathOrUrl(
    MusicTrack track, {
    bool forceOnline = false,
  }) async {
    try {
      final cacheKey = _makeMd5('${track.path}_${track.size}');
      final cacheFile = File(
        '${_localStore.configDirPath}/music_cache/audio_$cacheKey.dat',
      );
      if (!forceOnline && cacheFile.existsSync()) {
        return cacheFile.path;
      }

      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return '';

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/stream.view?$authParams&id=${track.id}';

      // 异步触发下载，如果当前没有处于下载队列中，则启动后台下载线程
      if (!_downloadingCacheKeys.contains(cacheKey)) {
        _downloadingCacheKeys.add(cacheKey);
        _downloadAndCacheAudio(url, cacheFile, track.id, cacheKey);
      }

      return url;
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to get audio path or URL: $e');
      return '';
    }
  }

  Future<void> _downloadAndCacheAudio(
    String url,
    File cacheFile,
    String trackId,
    String cacheKey,
  ) async {
    try {
      Log.d(
        LogGroup.network,
        'Starting background download for audio cache: ${cacheFile.path}',
      );
      final tmpFile = File('${cacheFile.path}.tmp');
      if (tmpFile.existsSync()) {
        await tmpFile.delete();
      }

      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode == 200) {
        final sink = tmpFile.openWrite();
        await response.stream.pipe(sink);
        await sink.close();

        // 只有下载完整且没有中断，才重命名为正式缓存文件
        await tmpFile.rename(cacheFile.path);
        Log.d(
          LogGroup.network,
          'Successfully cached audio to: ${cacheFile.path}',
        );
        if (!_isDisposed && !_cacheNotifier.isClosed) {
          _cacheNotifier.add(trackId); // 通知 UI 缓存完成
        }
      }
    } catch (e) {
      Log.d(LogGroup.network, 'Background audio caching failed: $e');
    } finally {
      _downloadingCacheKeys.remove(cacheKey);
    }
  }

  /// 🗑️ 清理指定歌曲的本地文件缓存与临时文件（多用于损坏缓存自愈）
  Future<void> clearTrackCache(MusicTrack track) async {
    try {
      final cacheKey = _makeMd5('${track.path}_${track.size}');
      _downloadingCacheKeys.remove(cacheKey);

      final cacheFile = File(
        '${_localStore.configDirPath}/music_cache/audio_$cacheKey.dat',
      );
      if (cacheFile.existsSync()) {
        await cacheFile.delete();
        Log.d(LogGroup.network, 'Cleaned corrupted track cache: ${cacheFile.path}');
      }
      final tmpFile = File('${cacheFile.path}.tmp');
      if (tmpFile.existsSync()) {
        await tmpFile.delete();
      }
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to clear track cache: $e');
    }
  }

  /// 🖼️ 5. 构建带鉴权的专辑/歌曲封面直链 (Get Cover Art URL)
  Future<String> getCoverArtUrl(String coverArtId) async {
    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return '';

      final authParams = await _buildAuthParams(endpoints);
      return '$baseUrl/rest/getCoverArt.view?$authParams&id=$coverArtId';
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to build cover art URL: $e');
      return '';
    }
  }

  /// 📝 6. 获取同步 LRC 歌词数据 (Fetch LRC Lyrics Data)
  /// Gonic 在后台会自动索引同目录下同名的 `.lrc` 歌词文件，并直接通过 `getLyrics.view` 返回。
  Future<String?> fetchLyrics(MusicTrack track) async {
    final cacheKey = _makeMd5('${track.path}_${track.size}');
    final cacheFile = File(
      '${_localStore.configDirPath}/music_cache/lyrics_$cacheKey.json',
    );

    if (cacheFile.existsSync()) {
      try {
        final content = await cacheFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        Log.d(LogGroup.network, 'Loaded lyrics from cache for: ${track.title}');
        return data['lyrics'] as String?;
      } catch (e) {
        Log.d(LogGroup.network, 'Failed to load lyrics from cache: $e');
      }
    }

    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return null;

      final authParams = await _buildAuthParams(endpoints);
      // 支持按歌手和歌名模糊检索歌词文本
      final queryParams =
          'artist=${Uri.encodeComponent(track.artist)}&title=${Uri.encodeComponent(track.title)}';
      final url = '$baseUrl/rest/getLyrics.view?$authParams&$queryParams';

      Log.d(
        LogGroup.network,
        'Fetching lyrics for: ${track.artist} - ${track.title}',
      );
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse =
            data['subsonic-response'] as Map<String, dynamic>? ?? {};
        final lyrics =
            subsonicResponse['lyrics'] as Map<String, dynamic>? ?? {};

        final String? lrcContent = lyrics['value'] as String?;
        if (lrcContent != null && lrcContent.trim().isNotEmpty) {
          Log.d(
            LogGroup.network,
            'Successfully retrieved synced LRC lyrics for: ${track.title}',
          );

          try {
            await cacheFile.writeAsString(jsonEncode({'lyrics': lrcContent}));
          } catch (e) {
            Log.d(LogGroup.network, 'Failed to write lyrics cache: $e');
          }

          return lrcContent;
        }
      }
    } catch (e) {
      Log.d(
        LogGroup.network,
        'Failed to fetch lyrics for: ${track.artist} - ${track.title}: $e',
      );
    }
    return null;
  }

  /// 📡 7. 触发 Gonic 开始全库增量扫描 (Trigger Subsonic Catalog Rescan)
  Future<bool> triggerScan() async {
    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return false;

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/startScan.view?$authParams';

      Log.d(LogGroup.network, 'Requesting Gonic scan via startScan.view');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse =
            data['subsonic-response'] as Map<String, dynamic>? ?? {};
        final status = subsonicResponse['status'] as String? ?? 'failed';
        Log.d(LogGroup.network, 'Gonic startScan trigger result: $status');
        return status == 'ok';
      }
      return false;
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to trigger Gonic scan: $e');
      return false;
    }
  }
}
