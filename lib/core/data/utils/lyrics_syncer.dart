import 'dart:convert';
import 'dart:io';
import '../../log/log.dart';
import '../repositories/music_repository.dart';

/// 🔄 歌词全自动同步器 (Zero-Touch Background Lyrics Syncer & Transcoder)
/// 在后台静默扫描本地磁盘目录中的所有 `.lrc` 文件，全自动：
/// 1. 解析编码：将 UTF-8 with BOM 或标准 UTF-8 进行安全去 BOM 并转为标准 UTF-8；
/// 2. 补齐标签：如果 LRC 文件内部缺少 `[ar: 歌手]` 或 `[ti: 歌名]`，根据文件名自动智能解析并补全写入，防范 Gonic 数据库匹配漏失；
/// 3. 生成伴侣：自动生成 Gonic 唯一支持的同名 `.txt` 歌词文件，解除人工维护命名后缀的痛苦；
/// 4. 触碰重扫：自动 Touch 音频文件最后修改时间，强制 Gonic 增量扫描器重扫，并自动触发 `startScan.view` 直达刷新！
class LyricsSyncer {
  /// 开启静默同步扫描任务
  static void startSilentSync() {
    // 异步执行，绝不阻塞应用主线程冷启动与 UI 渲染
    Future.delayed(const Duration(seconds: 4), () async {
      try {
        final dir = Directory('A:\\Media\\Music');
        if (!dir.existsSync()) {
          Log.d(LogGroup.network, 'Auto-Lyrics Syncer: Local music directory A:\\Media\\Music not found. Skipping.');
          return;
        }

        Log.d(LogGroup.network, 'Auto-Lyrics Syncer: Starting background scan in A:\\Media\\Music...');
        int syncedCount = 0;

        // 递归扫描所有文件夹中的 .lrc 文件
        final List<FileSystemEntity> entities = dir.listSync(recursive: true);
        for (var entity in entities) {
          if (entity is File && entity.path.toLowerCase().endsWith('.lrc')) {
            final bool updated = await _processLrcFile(entity);
            if (updated) {
              syncedCount++;
            }
          }
        }

        if (syncedCount > 0) {
          Log.d(LogGroup.network, 'Auto-Lyrics Syncer: Successfully synced and cloned $syncedCount lyric files. Requesting Gonic catalog rescan...');
          // 触发 Gonic 重新扫描以即刻载入新歌词！
          await MusicRepository.instance.triggerScan();
        } else {
          Log.d(LogGroup.network, 'Auto-Lyrics Syncer: Scan finished. All local lyrics are perfectly up to date.');
        }
      } catch (e) {
        Log.d(LogGroup.network, 'Auto-Lyrics Syncer error: $e');
      }
    });
  }

  /// 单个 LRC 文件的解码、补标签、克隆与热触碰逻辑
  static Future<bool> _processLrcFile(File lrcFile) async {
    try {
      final String lrcPath = lrcFile.path;
      final String parentPath = lrcFile.parent.path;
      final String baseName = lrcPath.substring(parentPath.length + 1, lrcPath.length - 4); // 取得不含后缀的文件名 (如 "周杰伦 - 烟花易冷")
      final String txtPath = '$parentPath\\$baseName.txt';

      final File txtFile = File(txtPath);

      // 如果 TXT 已经存在，且修改时间晚于 LRC，说明已经是最新状态，直接跳过避免重复开销
      if (txtFile.existsSync() && txtFile.lastModifiedSync().isAfter(lrcFile.lastModifiedSync())) {
        return false;
      }

      // 1. 安全读取并解码 LRC 内容
      final List<int> bytes = await lrcFile.readAsBytes();
      String content = '';
      
      // 检测 UTF-8 with BOM 并安全剥离
      if (bytes.length >= 3 && bytes[0] == 239 && bytes[1] == 187 && bytes[2] == 191) {
        content = utf8.decode(bytes.sublist(3), allowMalformed: true);
      } else {
        // 尝试用 UTF-8 解码，如果报错则采用容错机制
        try {
          content = utf8.decode(bytes);
        } catch (_) {
          content = utf8.decode(bytes, allowMalformed: true);
        }
      }

      // 清除 BOM 隐藏符与头部乱码
      content = content.replaceAll('\ufeff', '').trim();

      // 2. 智能缺失元数据标签补偿策略
      // 如果 LRC 内部缺少 [ar:] 歌手或 [ti:] 歌名标签，直接从文件名智能解析
      bool hasArtistTag = content.contains(RegExp(r'\[ar:\s*(.*?)\s*\]', caseSensitive: false));
      bool hasTitleTag = content.contains(RegExp(r'\[ti:\s*(.*?)\s*\]', caseSensitive: false));

      if (!hasArtistTag || !hasTitleTag) {
        // 尝试按常见的 "歌手 - 歌名" 拆分文件名
        String autoArtist = 'Unknown Artist';
        String autoTitle = baseName;

        if (baseName.contains(' - ')) {
          final parts = baseName.split(' - ');
          if (parts.length >= 2) {
            autoArtist = parts[0].trim();
            autoTitle = parts.sublist(1).join(' - ').trim();
          }
        }

        // 把计算出来的元数据标头插在歌词的最顶端
        String headerCompensation = '';
        if (!hasArtistTag) {
          headerCompensation += '[ar:$autoArtist]\n';
        }
        if (!hasTitleTag) {
          headerCompensation += '[ti:$autoTitle]\n';
        }

        content = headerCompensation + content;
      }

      // 3. 将经过转码、清洗与元数据注入的纯净歌词写入同名 .txt 文件
      await txtFile.writeAsString(content, encoding: utf8, flush: true);

      // 4. 热触碰（Touch）同名音频文件，强制 Gonic 启动增量扫描检测
      await _touchCompanionAudioFile(parentPath, baseName);

      Log.d(LogGroup.network, 'Auto-Lyrics Syncer: Synced and created partner TXT for "$baseName" successfully.');
      return true;
    } catch (e) {
      Log.d(LogGroup.network, 'Auto-Lyrics Syncer: Failed to process lyric file: ${lrcFile.path} | Error: $e');
      return false;
    }
  }

  /// 搜索并更新伴随音频文件的最后修改时间
  static Future<void> _touchCompanionAudioFile(String parentPath, String baseName) async {
    final List<String> audioExtensions = ['.flac', '.mp3', '.wav', '.m4a', '.aac', '.ogg'];
    for (var ext in audioExtensions) {
      final File audioFile = File('$parentPath\\$baseName$ext');
      if (audioFile.existsSync()) {
        try {
          final now = DateTime.now();
          await audioFile.setLastModified(now);
          await audioFile.setLastAccessed(now);
          break; // 触碰成功一个音频文件即可，立刻退出
        } catch (_) {}
      }
    }
  }
}
