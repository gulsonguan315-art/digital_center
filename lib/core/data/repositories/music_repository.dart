import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
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

  /// 全局唯一单例，由 DataManager 在初始化时注入绑定
  static late final MusicRepository instance;

  /// 用于微秒级随机数计算生成 Salt
  String _generateSalt() {
    final rand = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
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
  Future<void> saveMusicConfig(MusicConfig config) => _localStore.music.writeConfig(config);

  /// 📡 1. 验证 Gonic 服务器的连通性与账号密码正确性 (Ping Connection)
  Future<bool> pingServer() async {
    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return false;

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/ping.view?$authParams';

      Log.d(LogGroup.network, 'Pinging Gonic server at: $baseUrl');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse = data['subsonic-response'] as Map<String, dynamic>? ?? {};
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

  /// 📁 2. 获取 6 个物理词牌名根文件夹列表 (Fetch Physical Root Folders)
  /// 在 Gonic 优异的映射逻辑中，`getIndexes.view` 会将第一级子目录作为 Index/Artist 实体完美返回。
  Future<List<MusicFolder>> fetchRootFolders() async {
    final List<MusicFolder> folders = [];
    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return folders;

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/getIndexes.view?$authParams';

      Log.d(LogGroup.network, 'Fetching physical root folders from Gonic');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse = data['subsonic-response'] as Map<String, dynamic>? ?? {};
        final indexes = subsonicResponse['indexes'] as Map<String, dynamic>? ?? {};
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
        
        Log.d(LogGroup.network, 'Successfully parsed ${folders.length} root poetry folders from Gonic');
      }
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to fetch root folders from Gonic: $e');
    }
    return folders;
  }

  /// 🗂️ 3. 物理遍历指定目录内的歌曲与子文件夹 (Fetch Directory Contents)
  /// 根据物理目录的 ID 展开子目录与音频歌曲列表。
  Future<Map<String, dynamic>> fetchDirectoryContents(String folderId) async {
    final List<MusicFolder> subFolders = [];
    final List<MusicTrack> tracks = [];

    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) {
        return {'folders': subFolders, 'tracks': tracks};
      }

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/getMusicDirectory.view?$authParams&id=$folderId';

      Log.d(LogGroup.network, 'Fetching directory contents for ID: $folderId');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse = data['subsonic-response'] as Map<String, dynamic>? ?? {};
        final directory = subsonicResponse['directory'] as Map<String, dynamic>? ?? {};
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
        Log.d(LogGroup.network, 'Directory contents parsed: ${subFolders.length} subfolders, ${tracks.length} tracks');
      }
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to fetch directory contents for ID: $folderId: $e');
    }

    return {'folders': subFolders, 'tracks': tracks};
  }

  /// 🔗 4. 构建带鉴权的高保真流媒体播放直链 (Get Dynamic Audio Stream URL)
  /// 返回直接可供给播放器解码流式播放的 URL。
  Future<String> getAudioStreamUrl(String trackId) async {
    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return '';

      final authParams = await _buildAuthParams(endpoints);
      // Gonic 支持标准的 stream.view，支持传输原始 FLAC 格式无损音频
      return '$baseUrl/rest/stream.view?$authParams&id=$trackId';
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to build audio stream URL: $e');
      return '';
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
  Future<String?> fetchLyrics(String artist, String title) async {
    try {
      final endpoints = await _localStore.endpoints.readData();
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return null;

      final authParams = await _buildAuthParams(endpoints);
      // 支持按歌手和歌名模糊检索歌词文本
      final queryParams = 'artist=${Uri.encodeComponent(artist)}&title=${Uri.encodeComponent(title)}';
      final url = '$baseUrl/rest/getLyrics.view?$authParams&$queryParams';

      Log.d(LogGroup.network, 'Fetching lyrics for: $artist - $title');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse = data['subsonic-response'] as Map<String, dynamic>? ?? {};
        final lyrics = subsonicResponse['lyrics'] as Map<String, dynamic>? ?? {};
        
        final String? lrcContent = lyrics['value'] as String?;
        if (lrcContent != null && lrcContent.trim().isNotEmpty) {
          Log.d(LogGroup.network, 'Successfully retrieved synced LRC lyrics for: $title');
          return lrcContent;
        }
      }
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to fetch lyrics for: $artist - $title: $e');
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
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse = data['subsonic-response'] as Map<String, dynamic>? ?? {};
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
