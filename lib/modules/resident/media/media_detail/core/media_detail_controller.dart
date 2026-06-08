import 'package:flutter/material.dart';
import '../../../../../core/log/log.dart';
import '../../media_service.dart';

class MediaDetailController extends ChangeNotifier {
  final String itemId;

  Map<String, dynamic>? _rawDetails;
  bool isLoading = true;
  bool isError = false;

  /// 续播信息：下一集 item id（剧集返回 NextUp，电影返回自身）
  String? resumeItemId;

  /// 续播起始位置（ticks），0 = 从头播
  int resumePositionTicks = 0;

  /// 是否从 NextUp 成功解析出“继续观看”上下文（对剧集很有用）。
  /// 即使 NextUp 返回的单集当前 positionTicks == 0（比如刚好看完上一集），
  /// 只要 Jellyfin 认为这个是“下一集要看”的，就应该显示“续播”按钮。
  bool _nextUpResolved = false;

  /// 是否有历史进度（决定按钮文字：续播 vs 播放）
  /// 对于剧集：只要成功拿到 NextUp（表示用户有观看历史），就视为有“续播”语义。
  bool get hasResume => resumePositionTicks > 0 || _nextUpResolved;

  List<Map<String, dynamic>> processedPeople = [];

  MediaDetailController(this.itemId) {
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    _nextUpResolved = false;
    isLoading = true;
    notifyListeners();

    try {
      Log.d(LogGroup.media, '🔍 [Detail] 开始获取详情: $itemId');
      final details = await MediaService.instance.fetchItemDetails(itemId);
      if (details != null) {
        _rawDetails = details;
        _processPeople();
        Log.d(LogGroup.media, '✅ [Detail] 详情获取成功: type=$type, title=$title');
        if (type == 'Series') {
          await _fetchNextUp();
        } else {
          // 电影：读取自身进度
          final userData = details['UserData'] as Map<String, dynamic>?;
          resumePositionTicks =
              (userData?['PlaybackPositionTicks'] as int?) ?? 0;
          resumeItemId = itemId;
          final resumeSecs = resumePositionTicks ~/ 10000000;
          Log.d(
            LogGroup.media,
            '🎬 [Detail] 电影进度: resumePositionTicks=$resumePositionTicks (约${resumeSecs}s), hasResume=$hasResume',
          );
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
      notifyListeners();
    }
  }

  Future<void> _fetchNextUp() async {
    try {
      Log.d(LogGroup.media, '🔍 [Detail] 查询 NextUp: seriesId=$itemId');
      final nextUp = await MediaService.instance.fetchNextUp(itemId);
      if (nextUp != null) {
        resumeItemId = nextUp['Id'] as String?;
        final episodeName = nextUp['Name'] as String? ?? '未知';
        final seasonIndex = nextUp['ParentIndexNumber'] as int? ?? 0;
        final episodeIndex = nextUp['IndexNumber'] as int? ?? 0;
        final userData = nextUp['UserData'] as Map<String, dynamic>?;
        resumePositionTicks = (userData?['PlaybackPositionTicks'] as int?) ?? 0;
        _nextUpResolved = true; // 关键：只要 NextUp 命中，就认为有系列观看上下文
        final resumeSecs = resumePositionTicks ~/ 10000000;
        Log.d(
          LogGroup.media,
          '▶️ [Detail] NextUp 命中: S${seasonIndex}E${episodeIndex} "$episodeName" (id=$resumeItemId), '
          'positionTicks=$resumePositionTicks (约${resumeSecs}s), hasResume=$hasResume, _nextUpResolved=$_nextUpResolved',
        );
        return;
      }
      Log.d(LogGroup.media, '⚠️ [Detail] NextUp 为空 (未观看 or 已全部看完)，回退到第一集');
      _nextUpResolved = false;
      await _fetchFirstEpisode();
    } catch (e) {
      Log.d(LogGroup.media, '❌ [Detail] _fetchNextUp 异常: $e');
      await _fetchFirstEpisode();
    }
  }

  Future<void> _fetchFirstEpisode() async {
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
            resumeItemId = episodes.first['Id'] as String?;
            resumePositionTicks = 0;
            _nextUpResolved = false;
            Log.d(LogGroup.media, '✅ [Detail] 第一集: id=$resumeItemId (从头播放)');
          }
        }
      } else {
        Log.d(LogGroup.media, '⚠️ [Detail] 没有找到任何季数');
      }
    } catch (e) {
      Log.d(LogGroup.media, '❌ [Detail] _fetchFirstEpisode 异常: $e');
    }
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

  String? get playItemId => resumeItemId;

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
