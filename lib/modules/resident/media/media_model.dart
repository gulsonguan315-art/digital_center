/// 影视模块常驻常量 (Media Module Constants)
/// MediaItem 数据模型已迁移至 lib/core/data/models/media_item.dart
class MediaModel {
  static const String mediaPageId = 'mediaPage';

  /// 影视分类映射字典（用于 UI 标题显示）
  static const Map<String, String> categoryLabels = {
    'mov': '电影 / Movies',
    'tv':  '电视剧 / TV Shows',
    'ani': '动漫 / Anime',
    'doc': '纪录片 / Documentary',
    'adt': '成人专区 / Adult',
  };
}
