import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/media_item.dart';
import '../../../log/log.dart';

/// 🎬 影视元数据本地磁盘缓存子仓 (Local Media Metadata Cache Store)
/// 按分类各存一个 JSON 文件，只缓存元数据与海报 Tag，不缓存二进制媒体流。
/// 文件路径格式：{configDirPath}/media_cache_{category}.json
class LocalMediaStore {
  final String configDirPath;

  LocalMediaStore({required this.configDirPath});

  String _filePath(String category) =>
      '$configDirPath/media_cache_$category.json';

  // ---------------------------------------------------------------------------
  // 读取
  // ---------------------------------------------------------------------------

  /// 从磁盘读取指定分类的缓存条目列表。
  /// 文件不存在或解析失败时返回空列表，不抛异常（容错优先）。
  Future<List<MediaItem>> readCache(String category) async {
    if (kIsWeb) return [];
    try {
      final file = File(_filePath(category));
      if (!file.existsSync()) return [];

      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final list = jsonDecode(content) as List<dynamic>;
      return list
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Log.d(LogGroup.network, '⚠️ [MediaStore] 读取 $category 缓存失败: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 写入
  // ---------------------------------------------------------------------------

  /// 将条目列表写入磁盘缓存（直接覆写，无防抖）。
  /// 写入失败静默处理，不影响 UI 层正常展示已有内存缓存。
  Future<void> writeCache(String category, List<MediaItem> items) async {
    if (kIsWeb) return;
    try {
      final file = File(_filePath(category));
      final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
      await file.writeAsString(encoded, flush: true);
      Log.d(
        LogGroup.network,
        '✅ [MediaStore] $category 缓存已更新，共 ${items.length} 条',
      );
    } catch (e) {
      Log.d(LogGroup.network, '⚠️ [MediaStore] 写入 $category 缓存失败: $e');
    }
  }
}
