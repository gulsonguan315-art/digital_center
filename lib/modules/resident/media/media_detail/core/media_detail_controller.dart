import 'package:flutter/material.dart';
import '../../../../../core/log/log.dart';
import '../../media_service.dart';

class MediaDetailController extends ChangeNotifier {
  final String itemId;

  Map<String, dynamic>? _rawDetails;
  bool isLoading = true;
  bool isError = false;

  List<Map<String, dynamic>> processedPeople = [];

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  MediaDetailController(this.itemId) {
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      Log.d(LogGroup.media, '🔍 [Detail] 开始获取详情: $itemId');
      final details = await MediaService.instance.fetchItemDetails(itemId);
      if (details != null) {
        _rawDetails = details;
        _processPeople();
        Log.d(LogGroup.media, '✅ [Detail] 详情获取成功: type=$type, title=$title');
        if (type == 'Movie') {
          // 电影：如果需要，可以预加载电影自身的进度，但现在统统交由点击后解析
          Log.d(LogGroup.media, '🎬 [Detail] 电影详情已加载');
        }
      } else {
        isError = true;
        Log.d(LogGroup.media, '❌ [Detail] 详情获取失败: itemId=$itemId');
      }
    } catch (e) {
      isError = true;
      Log.d(LogGroup.media, '❌ [Detail] _fetchDetails 异常: $e');
    } finally {
      isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// 动态解析播放目标（点击播放/续播按钮时调用）
  /// [fromBeginning]: 若为 true，则强制从头播放（跳过续播查询，直接获取第一集或将进度清零）
  Future<Map<String, dynamic>?> resolvePlaybackData({bool fromBeginning = false}) async {
    try {
      if (type == 'Movie') {
        if (fromBeginning) {
          return {'id': itemId, 'ticks': 0};
        }
        final details = await MediaService.instance.fetchItemDetails(itemId);
        final userData = details?['UserData'] as Map<String, dynamic>?;
        final ticks = (userData?['PlaybackPositionTicks'] as int?) ?? 0;
        return {'id': itemId, 'ticks': ticks};
      } else {
        if (fromBeginning) {
          return await _fetchFirstEpisodeData();
        }
        
        Log.d(LogGroup.media, '🔍 [Detail] 动态查询 NextUp: seriesId=$itemId');
        final nextUp = await MediaService.instance.fetchNextUp(itemId);
        if (nextUp != null) {
          final resumeId = nextUp['Id'] as String?;
          final userData = nextUp['UserData'] as Map<String, dynamic>?;
          final ticks = (userData?['PlaybackPositionTicks'] as int?) ?? 0;
          if (resumeId != null) {
            return {'id': resumeId, 'ticks': ticks};
          }
        }
        Log.d(LogGroup.media, '⚠️ [Detail] NextUp 为空 (未观看 or 已全部看完)，回退到第一集');
        return await _fetchFirstEpisodeData();
      }
    } catch (e) {
      Log.d(LogGroup.media, '❌ [Detail] resolvePlaybackData 异常: $e');
      if (type == 'Series') {
        return await _fetchFirstEpisodeData();
      }
      return {'id': itemId, 'ticks': 0};
    }
  }

  Future<Map<String, dynamic>?> _fetchFirstEpisodeData() async {
    try {
      Log.d(LogGroup.media, '🔍 [Detail] 获取第一集: seriesId=$itemId');
      final seasons = await MediaService.instance.fetchSeasons(itemId);
      if (seasons.isNotEmpty) {
        final firstSeasonId = seasons.first['Id'] as String?;
        if (firstSeasonId != null) {
          final episodes = await MediaService.instance.fetchEpisodes(
            itemId,
            firstSeasonId,
          );
          if (episodes.isNotEmpty) {
            final firstEpId = episodes.first['Id'] as String?;
            if (firstEpId != null) {
              Log.d(LogGroup.media, '✅ [Detail] 第一集: id=$firstEpId (从头播放)');
              return {'id': firstEpId, 'ticks': 0};
            }
          }
        }
      }
    } catch (e) {
      Log.d(LogGroup.media, '❌ [Detail] _fetchFirstEpisodeData 异常: $e');
    }
    return null;
  }

  // 原始数据暴露给特定的子视图（如剧集视图需要深入解析 Season/Episode）
  Map<String, dynamic>? get rawDetails => _rawDetails;

  // 清洗后的安全 Getters，UI 直接取用
  String get title => _rawDetails?['Name'] as String? ?? 'Unknown';
  int? get year => _rawDetails?['ProductionYear'] as int?;
  double? get rating => (_rawDetails?['CommunityRating'] as num?)?.toDouble();
  String get overview => _rawDetails?['Overview'] as String? ?? '';
  String? get genres => (_rawDetails?['Genres'] as List<dynamic>?)?.join(' / ');

  String? get runtimeStr {
    final runTimeTicks = _rawDetails?['RunTimeTicks'] as int?;
    if (runTimeTicks != null) {
      final mins = runTimeTicks ~/ 60000000;
      return '${mins ~/ 60}h ${mins % 60}m';
    }
    return null;
  }

  String get backdropUrl {
    if (_rawDetails == null) return '';
    final tags = _rawDetails!['BackdropImageTags'] as List<dynamic>?;
    final tag = (tags != null && tags.isNotEmpty)
        ? tags.first.toString()
        : null;
    return MediaService.instance.backdropUrl(itemId, tag);
  }

  String get logoUrl {
    if (_rawDetails == null) return '';
    final imageTags = _rawDetails!['ImageTags'] as Map<String, dynamic>? ?? {};
    final logoTag = imageTags['Logo'] as String?;
    return logoTag != null
        ? MediaService.instance.logoUrl(itemId, logoTag)
        : '';
  }

  String get type => _rawDetails?['Type'] as String? ?? '';

  String? get playItemId => itemId;

  // 算法抽离：过滤无头像人员、去重、优先级排序、截断前 15 人
  void _processPeople() {
    final allPeople = (_rawDetails?['People'] as List<dynamic>?) ?? [];

    final coreStaff = <Map<String, dynamic>>[];
    final actors = <Map<String, dynamic>>[];

    for (final p in allPeople) {
      final person = p as Map<String, dynamic>;
      final type = person['Type'] as String? ?? '';
      final hasImage = person['PrimaryImageTag'] != null;

      if (!hasImage) continue;

      if (type == 'Director' || type == 'Writer') {
        if (!coreStaff.any((e) => e['Id'] == person['Id'])) {
          coreStaff.add(person);
        }
      } else if (type == 'Actor') {
        if (!actors.any((e) => e['Id'] == person['Id'])) {
          actors.add(person);
        }
      }
    }

    processedPeople = [...coreStaff, ...actors].take(15).toList();
  }
}
