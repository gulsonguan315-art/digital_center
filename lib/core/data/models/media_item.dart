/// 🎬 影视条目数据模型 (Media Item Data Model)
/// 字段对应 Jellyfin /Users/{userId}/Items API 返回结构。
/// 仅存储元数据与海报标签，不缓存二进制媒体流。
class MediaItem {
  /// Jellyfin 内部唯一条目 ID (ItemId)
  final String id;

  /// 条目显示名称 (Name)
  final String title;

  /// 出品年份 (ProductionYear)
  final int? year;

  /// 社区评分 (CommunityRating)
  final double? rating;

  /// 类型标签，已合并为 ' / ' 分隔的字符串 (Genres.join)
  final String? genre;

  /// 海报图片 Tag (ImageTags['Primary'])，用于构造海报 URL 并命中 CDN 缓存。
  /// 为 null 时海报区域使用占位色块。
  final String? posterTag;

  /// 我们系统内部的分类标识 ('mov' | 'tv' | 'ani' | 'doc' | 'adt')
  final String category;

  const MediaItem({
    required this.id,
    required this.title,
    required this.category,
    this.year,
    this.rating,
    this.genre,
    this.posterTag,
  });

  // ---------------------------------------------------------------------------
  // 序列化 (用于磁盘 JSON 缓存读写)
  // ---------------------------------------------------------------------------

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id:        json['id']       as String,
      title:     json['title']    as String,
      category:  json['category'] as String,
      year:      json['year']     as int?,
      rating:    (json['rating'] as num?)?.toDouble(),
      genre:     json['genre']    as String?,
      posterTag: json['posterTag'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'title':     title,
    'category':  category,
    if (year     != null) 'year':      year,
    if (rating   != null) 'rating':    rating,
    if (genre    != null) 'genre':     genre,
    if (posterTag != null) 'posterTag': posterTag,
  };

  // ---------------------------------------------------------------------------
  // 工厂：从 Jellyfin Items API 单条 JSON 映射
  // ---------------------------------------------------------------------------

  /// [category] 由调用方传入，因为 Jellyfin 本身不携带我们的内部分类标识
  factory MediaItem.fromJellyfin(
    Map<String, dynamic> json,
    String category,
  ) {
    final imageTags = json['ImageTags'] as Map<String, dynamic>? ?? {};
    final genres    = (json['Genres'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .take(3)
        .join(' / ');

    return MediaItem(
      id:        json['Id']               as String,
      title:     json['Name']             as String? ?? '未知',
      category:  category,
      year:      json['ProductionYear']   as int?,
      rating:    (json['CommunityRating'] as num?)?.toDouble(),
      genre:     genres?.isNotEmpty == true ? genres : null,
      posterTag: imageTags['Primary']     as String?,
    );
  }
}
