import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../local/local_config_store.dart';
import '../models/media_item.dart';
import '../models/user_settings.dart';
import '../../log/log.dart';

/// 📂 Jellyfin 影视数据专属仓库 (Jellyfin Media Domain Repository)
///
/// ## 缓存策略（SWR - Stale While Revalidate）
/// 1. [init]   启动时拉一次 `/Users/{id}/Views`，建立内存分类→LibraryId 映射表
/// 2. [watchCategory] 立即推磁盘缓存（本地优先秒出），后台静默同步 Jellyfin
///    · 有新内容 → 写盘 → 推 Stream（UI 自动刷新）
///    · 无变化   → 静默
/// 3. 同次会话切回已访问分类 → 命中内存缓存，不触发网络请求
class MediaRepository {
  MediaRepository(this._localStore);

  final LocalConfigStore _localStore;

  static late final MediaRepository instance;

  // --- 内存缓存 ---
  /// 分类 → Jellyfin Library ID（启动时 init 填充，整个会话有效）
  final Map<String, String> _libraryMap = {};

  /// 分类 → 条目列表（内存热缓存，避免重复网络请求）
  final Map<String, List<MediaItem>> _memCache = {};

  /// 分类 → Stream 控制器（懒创建，切分类时按需生成）
  final Map<String, StreamController<List<MediaItem>>> _controllers = {};

  bool _initialized = false;
  bool _isDisposed = false;

  // ---------------------------------------------------------------------------
  // 分类映射表（内部常量）
  // ---------------------------------------------------------------------------

  /// 我们的分类 ID → Jellyfin CollectionType 或 Library Name 关键词
  /// collectionType 优先匹配，name 关键词兜底
  static const _categoryCollectionType = <String, String>{
    'mov': 'movies',
    'tv':  'tvshows',
    // ani / doc 是独立 Library，通过 name 关键词匹配，见 _resolveLibraryName
  };

  static const _categoryNameKeywords = <String, List<String>>{
    'ani': ['动漫', 'anime', '二次元'],
    'doc': ['纪录片', 'documentary'],
  };

  // ---------------------------------------------------------------------------
  // 初始化
  // ---------------------------------------------------------------------------

  /// 启动时调用一次，从 Jellyfin `/Users/{id}/Views` 建立分类→LibraryId 映射。
  /// 建表完成后整个会话内不再重复请求 Views。
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final ep = await _endpoints;
      if (ep.jellyfinBaseUrl.isEmpty || ep.jellyfinToken.isEmpty) {
        Log.d(LogGroup.network, '⚠️ [Media] Jellyfin 配置未填写，跳过 Views 加载');
        return;
      }

      final url = Uri.parse(
        '${ep.jellyfinBaseUrl}/Users/${ep.jellyfinUserId}/Views',
      );
      final resp = await http
          .get(url, headers: _headers(ep.jellyfinToken))
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) {
        Log.d(LogGroup.network, '⚠️ [Media] Views 请求失败: ${resp.statusCode}');
        return;
      }

      final body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final items = (body['Items'] as List<dynamic>?) ?? [];

      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        final id   = item['Id']             as String? ?? '';
        final type = (item['CollectionType'] as String? ?? '').toLowerCase();
        final name = (item['Name']           as String? ?? '').toLowerCase();

        if (id.isEmpty) continue;

        // 1. CollectionType 直接匹配（mov / tv）
        for (final entry in _categoryCollectionType.entries) {
          if (type == entry.value && !_libraryMap.containsKey(entry.key)) {
            // tv / tvshows 只让第一个匹配的 Library 归入 tv，动漫另行按 name 匹配
            _libraryMap[entry.key] = id;
            Log.d(LogGroup.network,
              '✅ [Media] 分类 ${entry.key} → Library "$name" ($id)');
          }
        }

        // 2. Name 关键词匹配（ani / doc）
        for (final entry in _categoryNameKeywords.entries) {
          if (!_libraryMap.containsKey(entry.key)) {
            for (final kw in entry.value) {
              if (name.contains(kw)) {
                _libraryMap[entry.key] = id;
                // 动漫 Library 已单独归入 ani，从 tv 映射中移除（如果误匹配）
                if (entry.key == 'ani' && _libraryMap['tv'] == id) {
                  _libraryMap.remove('tv');
                }
                Log.d(LogGroup.network,
                  '✅ [Media] 分类 ${entry.key} → Library "$name" ($id) [name匹配]');
                break;
              }
            }
          }
        }
      }

      // 3. tv 被动漫占用时，重新找第一个 tvshows 非动漫 Library
      if (!_libraryMap.containsKey('tv')) {
        for (final raw in items) {
          final item = raw as Map<String, dynamic>;
          final id   = item['Id']             as String? ?? '';
          final type = (item['CollectionType'] as String? ?? '').toLowerCase();
          final libId = _libraryMap['ani'];
          if (type == 'tvshows' && id != libId) {
            _libraryMap['tv'] = id;
            Log.d(LogGroup.network, '✅ [Media] 重新绑定 tv Library: $id');
            break;
          }
        }
      }

      Log.d(LogGroup.network, '📋 [Media] 最终分类映射表: $_libraryMap');
    } catch (e) {
      Log.d(LogGroup.network, '⚠️ [Media] init() 异常: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 公开 API
  // ---------------------------------------------------------------------------

  /// 监听指定分类的条目列表（SWR Stream）。
  /// 每次调用立即推当前缓存，后台发起 Jellyfin 同步。
  Stream<List<MediaItem>> watchCategory(String category) {
    // 重用已有 Stream（同一分类切入时不重建）
    if (!_controllers.containsKey(category) ||
        _controllers[category]!.isClosed) {
      _controllers[category] = StreamController<List<MediaItem>>.broadcast(
        onCancel: () {
          // 当所有订阅者取消时（切出该分类），关闭并清理控制器
          _controllers[category]?.close();
          _controllers.remove(category);
        },
      );
      _emitAndSync(category);
    }
    return _controllers[category]!.stream;
  }

  /// 构造指定条目的海报图片 URL。
  /// [height] 默认 400px（对应典型 TV/显示器分辨率的海报列高）。
  String posterUrl(String itemId, String? tag, {int height = 400}) {
    final ep = _cachedEndpoints;
    if (ep == null || ep.jellyfinBaseUrl.isEmpty) return '';
    final tagParam = tag != null ? '&tag=$tag' : '';
    return '${ep.jellyfinBaseUrl}/Items/$itemId/Images/Primary'
        '?fillHeight=$height&quality=85$tagParam';
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }

  // ---------------------------------------------------------------------------
  // 内部实现
  // ---------------------------------------------------------------------------

  /// 【SWR 核心】立即推缓存，后台同步 Jellyfin
  Future<void> _emitAndSync(String category) async {
    // 1. 立即推内存缓存（如有）
    if (_memCache.containsKey(category)) {
      _emit(category, _memCache[category]!);
      _syncInBackground(category); // 有内存缓存时仍后台同步，但 UI 已秒出
      return;
    }

    // 2. 读磁盘缓存并立即推送
    final diskCache = await _localStore.media.readCache(category);
    if (diskCache.isNotEmpty) {
      _memCache[category] = diskCache;
      _emit(category, diskCache);
    }

    // 3. 后台向 Jellyfin 同步（无论磁盘缓存是否命中都执行）
    _syncInBackground(category);
  }

  /// 后台静默同步，对比内容有变化时刷新缓存并推送 Stream
  Future<void> _syncInBackground(String category) async {
    try {
      final ep = await _endpoints;
      if (ep.jellyfinBaseUrl.isEmpty || ep.jellyfinToken.isEmpty) return;

      final libraryId = _libraryMap[category];
      if (libraryId == null) {
        Log.d(LogGroup.network, '⚠️ [Media] 分类 $category 无对应 Library，跳过同步');
        return;
      }

      Log.d(LogGroup.network, '🔄 [Media] 后台同步分类: $category');

      final includeType = _jellyfinItemType(category);
      final url = Uri.parse(
        '${ep.jellyfinBaseUrl}/Users/${ep.jellyfinUserId}/Items'
        '?parentId=$libraryId'
        '&includeItemTypes=$includeType'
        '&recursive=true'
        '&fields=Genres,ProductionYear,CommunityRating,ImageTags'
        '&SortBy=SortName&SortOrder=Ascending'
        '&Limit=500',
      );

      final resp = await http
          .get(url, headers: _headers(ep.jellyfinToken))
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        Log.d(LogGroup.network, '⚠️ [Media] Items 请求失败: ${resp.statusCode}');
        return;
      }

      final body  = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final raws  = (body['Items'] as List<dynamic>?) ?? [];
      final fresh = raws
          .map((e) => MediaItem.fromJellyfin(e as Map<String, dynamic>, category))
          .toList();

      // 对比变化：ID 集合不同视为有更新
      final oldIds = (_memCache[category] ?? []).map((e) => e.id).toSet();
      final newIds = fresh.map((e) => e.id).toSet();
      final hasChange = !setEquals(oldIds, newIds);

      if (hasChange) {
        Log.d(LogGroup.network,
          '🆕 [Media] $category 内容已更新 (旧: ${oldIds.length} 条 → 新: ${fresh.length} 条)');
        _memCache[category] = fresh;
        _emit(category, fresh);
        // 异步写盘，不阻塞 UI
        unawaited(_localStore.media.writeCache(category, fresh));
      } else {
        Log.d(LogGroup.network, '✅ [Media] $category 内容无变化，保持缓存');
      }
    } catch (e) {
      Log.d(LogGroup.network, '⚠️ [Media] 后台同步异常 [$category]: $e');
      // 静默失败：UI 仍显示已有缓存，不中断体验
    }
  }

  void _emit(String category, List<MediaItem> items) {
    final controller = _controllers[category];
    if (controller != null && !controller.isClosed) {
      controller.add(items);
    }
  }

  static Map<String, String> _headers(String token) => {
    'X-Emby-Token': token,
    'Accept': 'application/json',
  };

  /// Jellyfin includeItemTypes 参数值
  static String _jellyfinItemType(String category) {
    return switch (category) {
      'tv'  => 'Series',
      'ani' => 'Series',
      _     => 'Movie', // mov / doc
    };
  }

  // ---------------------------------------------------------------------------
  // 端点懒缓存（避免每次 I/O）
  // ---------------------------------------------------------------------------

  ApiEndpoints? _cachedEndpoints;

  Future<ApiEndpoints> get _endpoints async {
    _cachedEndpoints ??= (await _localStore.userSettings.readData()).api;
    return _cachedEndpoints!;
  }
}

// 工具函数：忽略 Future 返回值（用于显式标记"不等待"）
void unawaited(Future<void> f) {}
