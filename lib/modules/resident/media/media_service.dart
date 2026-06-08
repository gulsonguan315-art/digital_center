import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/data/models/media_item.dart';
import '../../../core/data/repositories/media_repository.dart';

/// 异步加载状态枚举
enum MediaLoadState { idle, loading, loaded, error }

/// 🌍 影视服务中心 (Application-level Media Service)
/// 管理分类选择状态、条目列表，并通过 MediaRepository SWR 流实现本地优先秒出 + 后台静默更新。
class MediaService extends ChangeNotifier {
  static final MediaService instance = MediaService._();
  MediaService._();

  // ---------------------------------------------------------------------------
  // 状态
  // ---------------------------------------------------------------------------

  String _selectedCategory = 'mov';
  String get selectedCategory => _selectedCategory;

  List<MediaItem> _items = [];
  List<MediaItem> get items => _items;

  MediaLoadState _loadState = MediaLoadState.idle;
  MediaLoadState get loadState => _loadState;

  Rect? lastHeroRect;
  MediaItem? lastHeroItem;

  final Map<String, List<MediaItem>> _boxSetChildrenCache = {};
  Map<String, List<MediaItem>> get boxSetChildrenCache => _boxSetChildrenCache;

  StreamSubscription<List<MediaItem>>? _subscription;

  // ---------------------------------------------------------------------------
  // 详情页预加载缓存层 (Ephemeral Cache)
  // ---------------------------------------------------------------------------

  final Map<String, Map<String, dynamic>> _ephemeralDetailCache = {};
  final Map<String, Map<String, dynamic>> _ephemeralNextUpCache = {};

  /// 在跳转前，提前在主界面将网络请求和 JSON 解析跑完
  Future<void> preloadDetailData(MediaItem item) async {
    try {
      final details = await MediaRepository.instance.fetchItemDetails(item.id);
      if (details != null) {
        _ephemeralDetailCache[item.id] = details;
        if (item.jellyfinType == 'Series') {
          final nextUp = await MediaRepository.instance.fetchNextUp(item.id);
          if (nextUp != null) {
            _ephemeralNextUpCache[item.id] = nextUp;
          }
        }
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // 公开 API
  // ---------------------------------------------------------------------------

  /// 切换分类：取消旧订阅，订阅新分类的 SWR Stream。
  /// · 有磁盘缓存时立即触发第一次 notifyListeners，UI 秒出海报墙
  /// · 后台 Jellyfin 同步有更新时再次触发，UI 自动刷新
  void setCategory(String category) {
    if (_selectedCategory == category && _loadState == MediaLoadState.loaded) {
      return; // 同一分类已加载完成，无需重复操作
    }
    _selectedCategory = category;

    // 取消旧的 Stream 订阅
    _subscription?.cancel();
    _subscription = null;

    // 切换时先清空（避免显示上一个分类的残留数据）
    _items = [];
    _loadState = MediaLoadState.loading;
    notifyListeners();

    // 订阅新分类的 SWR Stream
    _subscription = MediaRepository.instance
        .watchCategory(category)
        .listen(
          (items) {
            _items = items;
            _loadState = MediaLoadState.loaded;
            notifyListeners();
          },
          onError: (_) {
            _loadState = MediaLoadState.error;
            notifyListeners();
          },
        );
  }

  /// 便捷方法：根据条目 id 获取海报图片 URL
  String posterUrl(String itemId, String? tag, {int height = 674}) =>
      MediaRepository.instance.posterUrl(itemId, tag, height: height);

  /// 根据条目 id 获取背景图片 URL
  String backdropUrl(String itemId, String? tag) =>
      MediaRepository.instance.backdropUrl(itemId, tag);

  /// 根据条目 id 获取 Logo 图片 URL
  String logoUrl(String itemId, String? tag) =>
      MediaRepository.instance.logoUrl(itemId, tag);

  /// 获取直接串流播放 URL
  String streamUrl(String itemId) => MediaRepository.instance.streamUrl(itemId);

  /// 详情页：在线拉取详情数据（优先走预加载幽灵缓存）
  Future<Map<String, dynamic>?> fetchItemDetails(String itemId) async {
    if (_ephemeralDetailCache.containsKey(itemId)) {
      return _ephemeralDetailCache.remove(itemId);
    }
    return await MediaRepository.instance.fetchItemDetails(itemId);
  }

  /// 获取剧集季数
  Future<List<Map<String, dynamic>>> fetchSeasons(String seriesId) async {
    return await MediaRepository.instance.fetchSeasons(seriesId);
  }

  /// 获取剧集某季的单集
  Future<List<Map<String, dynamic>>> fetchEpisodes(
    String seriesId,
    String seasonId,
  ) async {
    return await MediaRepository.instance.fetchEpisodes(seriesId, seasonId);
  }

  /// 预加载并缓存 BoxSet 子项
  Future<void> ensureBoxSetLoaded(String boxSetId) async {
    if (_boxSetChildrenCache.containsKey(boxSetId)) return;
    final items = await MediaRepository.instance.fetchBoxSetItems(boxSetId);
    _boxSetChildrenCache[boxSetId] = items;
    notifyListeners();
  }

  /// 汇报播放进度
  Future<void> reportPlaybackProgress(
    String itemId,
    int positionTicks, {
    String action = 'Playing/Progress',
    String? playSessionId,
  }) async {
    return await MediaRepository.instance.reportPlaybackProgress(
      itemId,
      positionTicks,
      action: action,
      playSessionId: playSessionId,
    );
  }

  /// 强制标记为已观看
  Future<void> markItemAsPlayed(String itemId) async {
    return await MediaRepository.instance.markItemAsPlayed(itemId);
  }

  /// 获取推荐的下一集 (NextUp)（优先走预加载幽灵缓存）
  Future<Map<String, dynamic>?> fetchNextUp(String seriesId) async {
    if (_ephemeralNextUpCache.containsKey(seriesId)) {
      return _ephemeralNextUpCache.remove(seriesId);
    }
    return await MediaRepository.instance.fetchNextUp(seriesId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
