import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../local/local_config_store.dart';
import '../models/music_data.dart';
import '../../log/log.dart';

/// 📂 音乐缓存管理器 (Music Cache Manager)
/// 只负责缓存路径、下载去重、坏文件清理、缓存完成及 EQ 生成事件通知，保持仓储层单一职责。
class MusicCacheManager {
  final LocalConfigStore _localStore;

  MusicCacheManager(this._localStore);

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
  static late final MusicCacheManager instance;

  String _makeMd5(String text) {
    return md5.convert(utf8.encode(text)).toString();
  }

  String _getNormalizedTrackPath(String path) {
    return path
        .replaceAll('/', Platform.pathSeparator)
        .replaceAll('\\', Platform.pathSeparator);
  }

  /// 📁 获取歌曲缓存的物理路径
  String getTrackCachePath(MusicTrack track) {
    final normalizedPath = _getNormalizedTrackPath(track.path);
    return '${_localStore.configDirPath}/music_cache/music/$normalizedPath';
  }

  /// 🔍 检查某首歌曲是否已经下载缓存到本地
  bool isTrackCached(MusicTrack track) {
    try {
      final cacheFile = File(getTrackCachePath(track));
      return cacheFile.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// 📡 触发后台异步下载和缓存
  void triggerDownload(MusicTrack track, String url) {
    final cacheKey = _makeMd5('${track.path}_${track.size}');
    if (_downloadingCacheKeys.contains(cacheKey)) {
      return; // 下载去重
    }
    _downloadingCacheKeys.add(cacheKey);
    final cacheFile = File(getTrackCachePath(track));
    _downloadAndCacheAudio(url, cacheFile, track, cacheKey);
  }

  Future<void> _downloadAndCacheAudio(
    String url,
    File cacheFile,
    MusicTrack track,
    String cacheKey,
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

        // 自动触发 EQ 预计算
        triggerEqGenerationForTrack(track);

        if (!_isDisposed && !_cacheNotifier.isClosed) {
          _cacheNotifier.add(track.id); // 通知 UI 缓存完成
        }
      }
    } catch (e) {
      Log.d(LogGroup.music, 'Background audio caching failed: $e');
    } finally {
      _downloadingCacheKeys.remove(cacheKey);
    }
  }

  /// ⚙️ 触发指定歌曲的后台频谱预计算任务
  void triggerEqGenerationForTrack(MusicTrack track) {
    final cacheKey = _makeMd5('${track.path}_${track.size}');
    final normalizedPath = _getNormalizedTrackPath(track.path);
    final cachePath = getTrackCachePath(track);
    _triggerEqGeneration(cachePath, cacheKey, normalizedPath);
  }

  /// ⚙️ 触发后台频谱预计算任务
  void _triggerEqGeneration(
    String audioPath,
    String cacheKey,
    String normalizedPath,
  ) async {
    final eqFile = File(
      '${_localStore.configDirPath}/music_cache/music/$normalizedPath.eq.json',
    );
    if (eqFile.existsSync()) return;

    final exePath = 'third_party/generate_eq.exe';

    // 确保父目录存在
    if (!eqFile.parent.existsSync()) {
      eqFile.parent.createSync(recursive: true);
    }

    // 解决 Windows 下 miniaudio/generate_eq.exe 对中文路径解析失败 的 Bug
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

  /// 🗑️ 清理指定歌曲的本地文件缓存与临时文件（多用于损坏缓存自愈）
  /// 如果当前正在后台下载该歌曲，则跳过清理以防临时文件写入冲突，并返回 false。
  Future<bool> clearTrackCache(MusicTrack track) async {
    try {
      final cacheKey = _makeMd5('${track.path}_${track.size}');
      if (_downloadingCacheKeys.contains(cacheKey)) {
        Log.d(
          LogGroup.music,
          'Cannot clear track cache: background download is currently in progress for ${track.title}',
        );
        return false;
      }

      final normalizedPath = _getNormalizedTrackPath(track.path);
      final cachePath = getTrackCachePath(track);
      final cacheFile = File(cachePath);
      if (cacheFile.existsSync()) {
        await cacheFile.delete();
        Log.d(
          LogGroup.music,
          'Cleaned corrupted track cache: ${cacheFile.path}',
        );
      }
      final tmpFile = File('$cachePath.tmp');
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
      return true;
    } catch (e) {
      Log.d(LogGroup.music, 'Failed to clear track cache: $e');
      return false;
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
}
