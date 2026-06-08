import '../../../../core/log/log.dart';
import '../../../resident/media/media_service.dart';
import 'media_immersive_controller.dart';

/// 播放决议的目标结果
class MediaTarget {
  final String id;
  final int ticks;

  const MediaTarget(this.id, this.ticks);
}

/// 播放前数据决议器
/// 
/// 专门负责在播放器启动前，查明真实要播放的视频 ID 以及准确的续播进度
class MediaTargetResolver {
  /// 解析最终要播放的实际条目 ID 以及起播的 Ticks 进度
  static Future<MediaTarget> resolve({
    required String sourceId,
    required String? mediaType,
    required int passedTicks,
    required bool forceStartOver,
    required void Function(PlaybackPhase) onPhaseChanged,
  }) async {
    String targetId = sourceId;
    int targetTicks = passedTicks;

    // 只有当没有从外部直接传入指定的进度，并且用户不是要求从头播放时，我们才去服务器拉取历史
    if (!forceStartOver && passedTicks == 0) {
      onPhaseChanged(PlaybackPhase.fetchingHistory);
      try {
        if (mediaType == 'Series') {
          final nextUp = await MediaService.instance.fetchNextUp(sourceId);
          if (nextUp != null) {
            targetId = nextUp['Id'] as String? ?? sourceId;
            final userData = nextUp['UserData'] as Map<String, dynamic>?;
            targetTicks = (userData?['PlaybackPositionTicks'] as int?) ?? 0;
          } else {
            final firstEpisodeId = await _resolveFirstEpisode(sourceId);
            if (firstEpisodeId != null) {
              targetId = firstEpisodeId;
              targetTicks = 0;
            }
          }
        } else {
          // 电影或单集：拉取当前物品详情以获取 UserData 进度
          final details = await MediaService.instance.fetchItemDetails(
            sourceId,
          );
          if (details != null) {
            final userData = details['UserData'] as Map<String, dynamic>?;
            targetTicks = (userData?['PlaybackPositionTicks'] as int?) ?? 0;
          }
        }
      } catch (e) {
        Log.d(LogGroup.media, '❌ [Player] 获取历史记录失败: $e');
      }
    } else if (mediaType == 'Series' && forceStartOver) {
      // 从头播放剧集：需要解析出第一集
      onPhaseChanged(PlaybackPhase.parsingFirstEpisode);
      try {
        final firstEpisodeId = await _resolveFirstEpisode(sourceId);
        if (firstEpisodeId != null) {
          targetId = firstEpisodeId;
          targetTicks = 0;
        }
      } catch (e) {
        Log.d(LogGroup.media, '❌ [Player] 解析第一集失败: $e');
      }
    } else if (forceStartOver) {
      targetTicks = 0;
    }

    return MediaTarget(targetId, targetTicks);
  }

  static Future<String?> _resolveFirstEpisode(String seriesId) async {
    final seasons = await MediaService.instance.fetchSeasons(seriesId);
    if (seasons.isNotEmpty) {
      final firstSeasonId = seasons.first['Id'] as String?;
      if (firstSeasonId != null) {
        final episodes = await MediaService.instance.fetchEpisodes(
          seriesId,
          firstSeasonId,
        );
        if (episodes.isNotEmpty) {
          return episodes.first['Id'] as String?;
        }
      }
    }
    return null;
  }

  /// 决议上一集/下一集的条目 ID（支持安全校验，如果无法切集则返回 null）
  static Future<String?> resolveRelativeEpisode(String currentItemId, int direction) async {
    final details = await MediaService.instance.fetchItemDetails(currentItemId);
    if (details == null || details['Type'] != 'Episode') return null;

    final seriesId = details['SeriesId'] as String?;
    final seasonId = details['SeasonId'] as String?;
    if (seriesId == null || seasonId == null) return null;

    final episodes = await MediaService.instance.fetchEpisodes(seriesId, seasonId);
    final currentIndex = episodes.indexWhere((ep) => ep['Id'] == currentItemId);
    if (currentIndex == -1) return null;

    final targetIndex = currentIndex + direction;
    if (targetIndex >= 0 && targetIndex < episodes.length) {
      return episodes[targetIndex]['Id'] as String?;
    }
    return null;
  }
}
