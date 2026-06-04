import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../local/local_config_store.dart';
import '../models/user_settings.dart';
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
    _eqNotifier.close();
    _downloadingCacheKeys.clear();
  }

  /// 跟踪正在后台下载的音频缓存 Key
  final Set<String> _downloadingCacheKeys = {};

  /// 广播缓存完成事件通知，String 为 track.id
  final _cacheNotifier = StreamController<String>.broadcast();
  Stream<String> get onTrackCached => _cacheNotifier.stream;

  /// 广播EQ生成完成事件通知，String 为 cacheKey
  final _eqNotifier = StreamController<String>.broadcast();
  Stream<String> get onEqGenerated => _eqNotifier.stream;

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
      final endpoints = (await _localStore.userSettings.readData()).api;
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return false;

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/ping.view?$authParams';

      Log.d(LogGroup.music, 'Pinging Gonic server at: $baseUrl');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse =
            data['subsonic-response'] as Map<String, dynamic>? ?? {};
        final status = subsonicResponse['status'] as String? ?? 'failed';

        Log.d(LogGroup.music, 'Gonic ping status: $status');
        return status == 'ok';
      }
      return false;
    } catch (e) {
      Log.d(LogGroup.music, 'Failed to ping Gonic server: $e');
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
          LogGroup.music,
          'Loaded ${folders.length} root folders from cache',
        );
        return folders;
      } catch (e) {
        Log.d(LogGroup.music, 'Failed to load root folders from cache: $e');
      }
    }
    try {
      final endpoints = (await _localStore.userSettings.readData()).api;
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return folders;

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/getIndexes.view?$authParams';

      Log.d(LogGroup.music, 'Fetching physical root folders from Gonic');
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
          LogGroup.music,
          'Successfully parsed ${folders.length} root poetry folders from Gonic',
        );

        try {
          final cacheData = folders.map((f) => f.toJson()).toList();
          await cacheFile.writeAsString(jsonEncode(cacheData));
        } catch (e) {
          Log.d(LogGroup.music, 'Failed to write root folders cache: $e');
        }
      }
    } catch (e) {
      Log.d(LogGroup.music, 'Failed to fetch root folders from Gonic: $e');
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
          LogGroup.music,
          'Loaded directory contents for ID: $folderId from cache',
        );
        return {'folders': subFolders, 'tracks': tracks};
      } catch (e) {
        Log.d(
          LogGroup.music,
          'Failed to load directory cache for ID: $folderId: $e',
        );
      }
    }

    try {
      final endpoints = (await _localStore.userSettings.readData()).api;
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) {
        return {'folders': subFolders, 'tracks': tracks};
      }

      final authParams = await _buildAuthParams(endpoints);
      final url =
          '$baseUrl/rest/getMusicDirectory.view?$authParams&id=$folderId';

      Log.d(LogGroup.music, 'Fetching directory contents for ID: $folderId');
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
          LogGroup.music,
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
            LogGroup.music,
            'Failed to write directory cache for ID: $folderId: $e',
          );
        }
      }
    } catch (e) {
      Log.d(
        LogGroup.music,
        'Failed to fetch directory contents for ID: $folderId: $e',
      );
    }

    return {'folders': subFolders, 'tracks': tracks};
  }

  String _getNormalizedTrackPath(String path) {
    return path
        .replaceAll('/', Platform.pathSeparator)
        .replaceAll('\\', Platform.pathSeparator);
  }

  /// 🔍 检查某首歌曲是否已经下载缓存到本地
  bool isTrackCached(MusicTrack track) {
    try {
      final normalizedPath = _getNormalizedTrackPath(track.path);
      final cacheFile = File(
        '${_localStore.configDirPath}/music_cache/music/$normalizedPath',
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
      final normalizedPath = _getNormalizedTrackPath(track.path);
      final cacheFile = File(
        '${_localStore.configDirPath}/music_cache/music/$normalizedPath',
      );
      if (!forceOnline && cacheFile.existsSync()) {
        _triggerEqGeneration(cacheFile.path, cacheKey, normalizedPath);
        return cacheFile.path;
      }

      final endpoints = (await _localStore.userSettings.readData()).api;
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return '';

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/stream.view?$authParams&id=${track.id}';

      // 异步触发下载，如果当前没有处于下载队列中，则启动后台下载线程
      if (!_downloadingCacheKeys.contains(cacheKey)) {
        _downloadingCacheKeys.add(cacheKey);
        _downloadAndCacheAudio(url, cacheFile, track.id, cacheKey, normalizedPath);
      }

      return url;
    } catch (e) {
      Log.d(LogGroup.music, 'Failed to get audio path or URL: $e');
      return '';
    }
  }

  Future<void> _downloadAndCacheAudio(
    String url,
    File cacheFile,
    String trackId,
    String cacheKey,
    String normalizedPath,
  ) async {
    try {
      Log.d(
        LogGroup.music,
        'Starting background download for audio cache: ${cacheFile.path}',
      );
      if (!cacheFile.parent.existsSync()) {
        cacheFile.parent.createSync(recursive: true);
      }
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
          LogGroup.music,
          'Successfully cached audio to: ${cacheFile.path}',
        );
        _triggerEqGeneration(cacheFile.path, cacheKey, normalizedPath);
        if (!_isDisposed && !_cacheNotifier.isClosed) {
          _cacheNotifier.add(trackId); // 通知 UI 缓存完成
        }
      }
    } catch (e) {
      Log.d(LogGroup.music, 'Background audio caching failed: $e');
    } finally {
      _downloadingCacheKeys.remove(cacheKey);
    }
  }

  /// 🗑️ 清理指定歌曲的本地文件缓存与临时文件（多用于损坏缓存自愈）
  Future<void> clearTrackCache(MusicTrack track) async {
    try {
      final cacheKey = _makeMd5('${track.path}_${track.size}');
      _downloadingCacheKeys.remove(cacheKey);

      final normalizedPath = _getNormalizedTrackPath(track.path);
      final cacheFile = File(
        '${_localStore.configDirPath}/music_cache/music/$normalizedPath',
      );
      if (cacheFile.existsSync()) {
        await cacheFile.delete();
        Log.d(
          LogGroup.music,
          'Cleaned corrupted track cache: ${cacheFile.path}',
        );
      }
      final tmpFile = File('${cacheFile.path}.tmp');
      if (tmpFile.existsSync()) {
        await tmpFile.delete();
      }

      final lyricsCacheFile = File(
        '${_localStore.configDirPath}/music_cache/music/$normalizedPath.lyrics.json',
      );
      if (lyricsCacheFile.existsSync()) {
        await lyricsCacheFile.delete();
      }

      final eqCacheFile = File(
        '${_localStore.configDirPath}/music_cache/music/$normalizedPath.eq.json',
      );
      if (eqCacheFile.existsSync()) {
        await eqCacheFile.delete();
      }

      // 递归清理空父文件夹
      _deleteEmptyParents(cacheFile, '${_localStore.configDirPath}/music_cache/music');
    } catch (e) {
      Log.d(LogGroup.music, 'Failed to clear track cache: $e');
    }
  }

  /// 🗑️ 清理指定物理文件夹路径的全部本地缓存（包含音频、EQ、歌词）
  Future<void> clearFolderCache(String relativeFolderPath) async {
    try {
      final normalizedFolder = _getNormalizedTrackPath(relativeFolderPath);
      final folderDir = Directory(
        '${_localStore.configDirPath}/music_cache/music/$normalizedFolder',
      );
      if (folderDir.existsSync()) {
        await folderDir.delete(recursive: true);
        Log.d(LogGroup.music, 'Cleaned folder cache recursively: ${folderDir.path}');
        
        // 递归清理上级空父文件夹
        _deleteEmptyParents(File('${folderDir.path}/dummy.txt'), '${_localStore.configDirPath}/music_cache/music');
      }
    } catch (e) {
      Log.d(LogGroup.music, 'Failed to clear folder cache: $e');
    }
  }

  /// 递归清理空父文件夹，直到遇到 stopAtPath
  void _deleteEmptyParents(File file, String stopAtPath) {
    try {
      Directory parent = file.parent;
      final stopDir = Directory(stopAtPath);
      while (parent.path != stopDir.path && parent.existsSync()) {
        if (parent.listSync().isEmpty) {
          parent.deleteSync();
          parent = parent.parent;
        } else {
          break;
        }
      }
    } catch (_) {}
  }

  /// ⚙️ 触发后台频谱预计算任务
  void _triggerEqGeneration(String audioPath, String cacheKey, String normalizedPath) async {
    final eqFile = File(
      '${_localStore.configDirPath}/music_cache/music/$normalizedPath.eq.json',
    );
    if (eqFile.existsSync()) return;

    final exePath = 'third_party/generate_eq.exe';

    // 确保父目录存在
    if (!eqFile.parent.existsSync()) {
      eqFile.parent.createSync(recursive: true);
    }

    // 解决 Windows 下 miniaudio/generate_eq.exe 对中文路径解析失败 (ERROR: failed to decode file) 的 Bug
    // 方案：将音频复制到 ASCII 临时路径，运行生成后再移动 JSON 结果
    final tmpAudioFile = File(
      '${_localStore.configDirPath}/music_cache/tmp_audio_$cacheKey.tmp',
    );
    final tmpEqFile = File(
      '${_localStore.configDirPath}/music_cache/tmp_eq_$cacheKey.json',
    );

    try {
      final sourceFile = File(audioPath);
      if (!sourceFile.existsSync()) return;
      await sourceFile.copy(tmpAudioFile.path);

      Process.run(exePath, [tmpAudioFile.path, tmpEqFile.path])
          .then((result) async {
            // 无论成功还是失败，均需要安全清理临时音频文件
            try {
              if (tmpAudioFile.existsSync()) {
                await tmpAudioFile.delete();
              }
            } catch (_) {}

            if (result.exitCode == 0 && tmpEqFile.existsSync()) {
              try {
                if (eqFile.existsSync()) {
                  await eqFile.delete();
                }
                await tmpEqFile.rename(eqFile.path);
                Log.d(LogGroup.music, 'Successfully generated EQ for: $cacheKey');
                if (!_isDisposed && !_eqNotifier.isClosed) {
                  _eqNotifier.add(cacheKey);
                }
              } catch (e) {
                Log.d(LogGroup.music, 'Failed to rename EQ file: $e');
              }
            } else {
              Log.d(LogGroup.music, 'Failed to generate EQ: ${result.stderr}');
            }

            // 清理临时 EQ 文件（如果未重命名成功或失败残留）
            try {
              if (tmpEqFile.existsSync()) {
                await tmpEqFile.delete();
              }
            } catch (_) {}
          })
          .catchError((e) async {
            Log.d(LogGroup.music, 'Failed to launch generate_eq.exe: $e');
            // 清理临时文件
            try {
              if (tmpAudioFile.existsSync()) await tmpAudioFile.delete();
              if (tmpEqFile.existsSync()) await tmpEqFile.delete();
            } catch (_) {}
          });
    } catch (e) {
      Log.d(LogGroup.music, 'Failed to setup temporary files for EQ generation: $e');
      try {
        if (tmpAudioFile.existsSync()) await tmpAudioFile.delete();
        if (tmpEqFile.existsSync()) await tmpEqFile.delete();
      } catch (_) {}
    }
  }

  /// 🖼️ 5. 构建带鉴权的专辑/歌曲封面直链 (Get Cover Art URL)
  Future<String> getCoverArtUrl(String coverArtId) async {
    try {
      final endpoints = (await _localStore.userSettings.readData()).api;
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return '';

      final authParams = await _buildAuthParams(endpoints);
      return '$baseUrl/rest/getCoverArt.view?$authParams&id=$coverArtId';
    } catch (e) {
      Log.d(LogGroup.music, 'Failed to build cover art URL: $e');
      return '';
    }
  }

  /// 📝 6. 获取同步 LRC 歌词数据 (Fetch LRC Lyrics Data)
  /// Gonic 在后台会自动索引同目录下同名的 `.lrc` 歌词文件，并直接通过 `getLyrics.view` 返回。
  Future<(String?, int)> fetchLyrics(MusicTrack track) async {
    final normalizedPath = _getNormalizedTrackPath(track.path);
    final cacheFile = File(
      '${_localStore.configDirPath}/music_cache/music/$normalizedPath.lyrics.json',
    );

    if (cacheFile.existsSync()) {
      try {
        final content = await cacheFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        final isExported = data['is_exported'] as bool? ?? false;
        if (isExported) {
          final trackPath = track.path;
          final lastDot = trackPath.lastIndexOf('.');
          final lrcPath =
              (lastDot != -1 ? trackPath.substring(0, lastDot) : trackPath) +
              '.lrc';
          final exportedFile = File(
            '${_localStore.configDirPath}/music_cache/exported_lyrics/$lrcPath',
          );

          if (!exportedFile.existsSync()) {
            // 如果已导出，且 exported_lyrics 中的 .lrc 被删除了，说明 Python 同步脚本已经处理了！
            // 此时 NAS 音频文件已被内嵌歌词（但文件 Size 未必改变）。
            // 我们主动删掉过时的本地缓存，强制去向 Gonic 要新的内嵌歌词（新歌词的时间轴已经是修正过的）。
            Log.d(
              LogGroup.music,
              'Exported .lrc is gone, invalidating lyrics cache for: ${track.title}',
            );
            cacheFile.deleteSync();
            // 穿透到下方重新拉取网络请求
          } else {
            Log.d(
              LogGroup.music,
              'Loaded lyrics from cache for: ${track.title}',
            );
            final lrc = data['lyrics'] as String?;
            final offsetMs = data['offset_ms'] as int? ?? 0;
            if (lrc != null && lrc.isEmpty) return (null, offsetMs);
            return (lrc, offsetMs);
          }
        } else {
          Log.d(LogGroup.music, 'Loaded lyrics from cache for: ${track.title}');
          final lrc = data['lyrics'] as String?;
          final offsetMs = data['offset_ms'] as int? ?? 0;
          if (lrc != null && lrc.isEmpty) return (null, offsetMs);
          return (lrc, offsetMs);
        }
      } catch (e) {
        Log.d(LogGroup.music, 'Failed to load lyrics from cache: $e');
      }
    }

    try {
      final endpoints = (await _localStore.userSettings.readData()).api;
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return (null, 0);

      final authParams = await _buildAuthParams(endpoints);
      // 支持按歌手和歌名模糊检索歌词文本
      final queryParams =
          'artist=${Uri.encodeComponent(track.artist)}&title=${Uri.encodeComponent(track.title)}';
      final url = '$baseUrl/rest/getLyrics.view?$authParams&$queryParams';

      Log.d(
        LogGroup.music,
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

        // 核心修复：无论服务器返回是否有歌词，只要请求成功（200），我们就缓存下来！
        // 如果没有歌词，我们缓存一个空字符串，这样下次直接拦截，不再发起网络请求。
        try {
          if (!cacheFile.parent.existsSync()) {
            cacheFile.parent.createSync(recursive: true);
          }
          await cacheFile.writeAsString(
            jsonEncode({'lyrics': lrcContent ?? '', 'offset_ms': 0}),
          );
        } catch (e) {
          Log.d(LogGroup.music, 'Failed to write lyrics cache: $e');
        }

        if (lrcContent != null && lrcContent.trim().isNotEmpty) {
          Log.d(
            LogGroup.music,
            'Successfully retrieved synced LRC lyrics for: ${track.title}',
          );
          return (lrcContent, 0);
        }
      }
    } catch (e) {
      Log.d(
        LogGroup.music,
        'Failed to fetch lyrics for: ${track.artist} - ${track.title}: $e',
      );
    }
    return (null, 0);
  }

  /// 📝 7. 更新本地缓存的歌词偏移量
  /// 用于用户在前端微调了歌词时间轴后，不改变原始歌词文本，仅更新缓存头部的 `offset_ms` 字段
  Future<void> updateLyricsCacheOffset(
    MusicTrack track,
    int offsetMs, {
    bool isExported = false,
  }) async {
    final normalizedPath = _getNormalizedTrackPath(track.path);
    final cacheFile = File(
      '${_localStore.configDirPath}/music_cache/music/$normalizedPath.lyrics.json',
    );
    if (!cacheFile.existsSync()) return;

    try {
      final content = await cacheFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      data['offset_ms'] = offsetMs;
      if (isExported) data['is_exported'] = true;
      await cacheFile.writeAsString(jsonEncode(data));
      Log.d(
        LogGroup.music,
        'Updated lyrics offset to ${offsetMs}ms for: ${track.title}',
      );
    } catch (e) {
      Log.d(LogGroup.music, 'Failed to update lyrics cache offset: $e');
    }
  }

  /// 📡 7. 触发 Gonic 开始全库增量扫描 (Trigger Subsonic Catalog Rescan)
  Future<bool> triggerScan() async {
    try {
      final endpoints = (await _localStore.userSettings.readData()).api;
      final baseUrl = endpoints.gonicBaseUrl;
      if (baseUrl.isEmpty) return false;

      final authParams = await _buildAuthParams(endpoints);
      final url = '$baseUrl/rest/startScan.view?$authParams';

      Log.d(LogGroup.music, 'Requesting Gonic scan via startScan.view');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content) as Map<String, dynamic>;
        final subsonicResponse =
            data['subsonic-response'] as Map<String, dynamic>? ?? {};
        final status = subsonicResponse['status'] as String? ?? 'failed';
        Log.d(LogGroup.music, 'Gonic startScan trigger result: $status');
        return status == 'ok';
      }
      return false;
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to trigger Gonic scan: $e');
      return false;
    }
  }
}
