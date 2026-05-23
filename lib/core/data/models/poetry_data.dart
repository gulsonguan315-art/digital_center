import 'package:flutter/foundation.dart';

/// Represents today's daily poetry fetched from the remote API server.
class PoetryData {
  final String id;
  final String title;
  final String author;
  final List<String> paragraphs;
  final String date;
  final List<int> markedLines; // 🌟 新增：用户划线的行号索引数组

  const PoetryData({
    required this.id,
    required this.title,
    required this.author,
    required this.paragraphs,
    required this.date,
    this.markedLines = const [],
  });

  /// Default mock fallback
  static const PoetryData defaultPoetry = PoetryData(
    id: 'test_001',
    title: '滕王阁序',
    author: '王勃',
    paragraphs: ['落霞与孤鹜齐飞，秋水共长天一色。'],
    date: '2026-05-17',
    markedLines: [],
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'paragraphs': paragraphs,
      'date': date,
      'marked_lines': markedLines, // 🌟 字段映射后端 sqlite 的 marked_lines
    };
  }

  factory PoetryData.fromJson(Map<String, dynamic> json) {
    return PoetryData(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '未知') as String,
      author: (json['author'] ?? '佚名') as String,
      paragraphs: List<String>.from(json['paragraphs'] ?? []),
      date: (json['date'] ?? '') as String,
      markedLines: List<int>.from(json['marked_lines'] ?? []), // 🌟 防御式空数组解析
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PoetryData &&
        other.id == id &&
        other.title == title &&
        other.author == author &&
        other.date == date &&
        listEquals(other.paragraphs, paragraphs) && // 🌟 对段落内容执行深比较
        listEquals(other.markedLines, markedLines); // 🌟 对列表行号执行深比较去重
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      author,
      date,
      Object.hashAll(paragraphs),
      Object.hashAll(markedLines),
    );
  }
}
