import 'package:flutter/material.dart';
import '../../media_service.dart';

class MediaDetailController extends ChangeNotifier {
  final String itemId;
  
  Map<String, dynamic>? _rawDetails;
  bool isLoading = true;
  bool isError = false;

  String? firstEpisodeId;
  List<Map<String, dynamic>> processedPeople = [];

  MediaDetailController(this.itemId) {
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    isLoading = true;
    notifyListeners();

    try {
      final details = await MediaService.instance.fetchItemDetails(itemId);
      if (details != null) {
        _rawDetails = details;
        _processPeople();
        if (type == 'Series') {
          await _fetchFirstEpisode();
        }
      } else {
        isError = true;
      }
    } catch (e) {
      isError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFirstEpisode() async {
    try {
      final seasons = await MediaService.instance.fetchSeasons(itemId);
      if (seasons.isNotEmpty) {
        final firstSeasonId = seasons.first['Id'] as String?;
        if (firstSeasonId != null) {
          final episodes = await MediaService.instance.fetchEpisodes(itemId, firstSeasonId);
          if (episodes.isNotEmpty) {
            firstEpisodeId = episodes.first['Id'] as String?;
          }
        }
      }
    } catch (_) {
      // Ignore errors for first episode fetching
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
    final tag = (tags != null && tags.isNotEmpty) ? tags.first.toString() : null;
    return MediaService.instance.backdropUrl(itemId, tag);
  }

  String get logoUrl {
    if (_rawDetails == null) return '';
    final imageTags = _rawDetails!['ImageTags'] as Map<String, dynamic>? ?? {};
    final logoTag = imageTags['Logo'] as String?;
    return logoTag != null ? MediaService.instance.logoUrl(itemId, logoTag) : '';
  }

  String get type => _rawDetails?['Type'] as String? ?? '';

  String? get playItemId => type == 'Series' ? firstEpisodeId : itemId;

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
