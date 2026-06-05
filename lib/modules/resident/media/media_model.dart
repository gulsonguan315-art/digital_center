import 'package:flutter/material.dart';

/// 影视单项数据模型
class MediaItem {
  final String id;
  final String title;
  final String category; // 'mov', 'tv', 'ani', 'doc', 'adt'
  final String year;
  final double rating;
  final String genre;
  final List<Color> gradientColors;

  const MediaItem({
    required this.id,
    required this.title,
    required this.category,
    required this.year,
    required this.rating,
    required this.genre,
    required this.gradientColors,
  });
}

/// 影视配置与常驻常量模型
class MediaModel {
  static const String mediaPageId = 'mediaPage';

  // 影视分类映射字典
  static const Map<String, String> categoryLabels = {
    'mov': '电影 / Movies',
    'tv': '电视剧 / TV Shows',
    'ani': '动漫 / Anime',
    'doc': '纪录片 / Documentary',
    'adt': '成人专区 / Adult',
  };

  // 种子测试数据：生成丰富、精美的高品质影视占位条目
  static const List<MediaItem> mockItems = [
    // 1. 电影 (mov)
    MediaItem(
      id: 'media_item_mov_01',
      title: '银翼杀手 2049',
      category: 'mov',
      year: '2017',
      rating: 8.5,
      genre: '科幻 / 动作 / 惊悚',
      gradientColors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    ),
    MediaItem(
      id: 'media_item_mov_02',
      title: '星际穿越',
      category: 'mov',
      year: '2014',
      rating: 9.4,
      genre: '科幻 / 冒险 / 剧情',
      gradientColors: [Color(0xFF141E30), Color(0xFF243B55)],
    ),
    MediaItem(
      id: 'media_item_mov_03',
      title: '沙丘：第二部',
      category: 'mov',
      year: '2024',
      rating: 8.3,
      genre: '科幻 / 冒险 / 动作',
      gradientColors: [Color(0xFF8A5A36), Color(0xFF422E1B)],
    ),
    MediaItem(
      id: 'media_item_mov_04',
      title: '黑客帝国',
      category: 'mov',
      year: '1999',
      rating: 9.1,
      genre: '科幻 / 动作',
      gradientColors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
    ),
    MediaItem(
      id: 'media_item_mov_05',
      title: '盗梦空间',
      category: 'mov',
      year: '2010',
      rating: 9.3,
      genre: '科幻 / 悬疑 / 动作',
      gradientColors: [Color(0xFF232526), Color(0xFF414345)],
    ),
    MediaItem(
      id: 'media_item_mov_06',
      title: '流浪地球 2',
      category: 'mov',
      year: '2023',
      rating: 8.3,
      genre: '科幻 / 灾难',
      gradientColors: [Color(0xFF3E5151), Color(0xFFDECBA4)],
    ),

    // 2. 电视剧 (tv)
    MediaItem(
      id: 'media_item_tv_01',
      title: '三体',
      category: 'tv',
      year: '2023',
      rating: 8.7,
      genre: '科幻 / 悬疑 / 剧情',
      gradientColors: [Color(0xFF111111), Color(0xFF2C3E50)],
    ),
    MediaItem(
      id: 'media_item_tv_02',
      title: '切尔诺贝利',
      category: 'tv',
      year: '2019',
      rating: 9.6,
      genre: '剧情 / 历史 / 灾难',
      gradientColors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
    ),
    MediaItem(
      id: 'media_item_tv_03',
      title: '绝命毒师',
      category: 'tv',
      year: '2008',
      rating: 9.7,
      genre: '剧情 / 犯罪 / 惊悚',
      gradientColors: [Color(0xFF1D4350), Color(0xFFF46B45)],
    ),
    MediaItem(
      id: 'media_item_tv_04',
      title: '黑镜',
      category: 'tv',
      year: '2011',
      rating: 9.2,
      genre: '科幻 / 惊悚 / 讽刺',
      gradientColors: [Color(0xFF000000), Color(0xFF434343)],
    ),

    // 3. 动漫 (ani)
    MediaItem(
      id: 'media_item_ani_01',
      title: '赛博朋克：边缘行者',
      category: 'ani',
      year: '2022',
      rating: 9.0,
      genre: '动作 / 科幻 / 冒险',
      gradientColors: [Color(0xFFF12711), Color(0xFFF5AF19)],
    ),
    MediaItem(
      id: 'media_item_ani_02',
      title: '攻壳机动队 S.A.C.',
      category: 'ani',
      year: '2002',
      rating: 9.6,
      genre: '科幻 / 警匪 / 哲学',
      gradientColors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
    ),
    MediaItem(
      id: 'media_item_ani_03',
      title: '新世纪福音战士 (EVA)',
      category: 'ani',
      year: '1995',
      rating: 9.5,
      genre: '剧情 / 科幻 / 心理',
      gradientColors: [Color(0xFF654ea3), Color(0xFFeaafc8)],
    ),
    MediaItem(
      id: 'media_item_ani_04',
      title: '死亡笔记',
      category: 'ani',
      year: '2006',
      rating: 9.2,
      genre: '悬疑 / 智斗 / 超自然',
      gradientColors: [Color(0xFF1f4037), Color(0xFF99f2c8)],
    ),

    // 4. 纪录片 (doc)
    MediaItem(
      id: 'media_item_doc_01',
      title: '地球脉动：第三季',
      category: 'doc',
      year: '2023',
      rating: 9.8,
      genre: '自然 / 生态',
      gradientColors: [Color(0xFF56ab2f), Color(0xFFa8ff78)],
    ),
    MediaItem(
      id: 'media_item_doc_02',
      title: '宇宙的奇迹',
      category: 'doc',
      year: '2011',
      rating: 9.5,
      genre: '科学 / 探索',
      gradientColors: [Color(0xFF4568DC), Color(0xFFB06AB8)],
    ),
    MediaItem(
      id: 'media_item_doc_03',
      title: '舌尖上的中国',
      category: 'doc',
      year: '2012',
      rating: 9.4,
      genre: '美食 / 人文',
      gradientColors: [Color(0xFFD38312), Color(0xFFA83279)],
    ),

    // 5. 成人专区 (adt)
    MediaItem(
      id: 'media_item_adt_01',
      title: '影视制作幕后特辑 (NC-17)',
      category: 'adt',
      year: '2024',
      rating: 8.8,
      genre: '艺术 / 限制级',
      gradientColors: [Color(0xFF800080), Color(0xFFffc0cb)],
    ),
    MediaItem(
      id: 'media_item_adt_02',
      title: '深夜剧场特约 (18+)',
      category: 'adt',
      year: '2023',
      rating: 7.9,
      genre: '剧情 / 限制级',
      gradientColors: [Color(0xFFe65c00), Color(0xFFF9D423)],
    ),
  ];
}
