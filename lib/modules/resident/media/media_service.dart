import 'package:flutter/material.dart';

/// 🌍 影视服务中心状态大总管 (Application-level Media Service)
class MediaService extends ChangeNotifier {
  static final MediaService instance = MediaService._();
  MediaService._();

  String _selectedCategory = 'mov'; // 默认分类：电影 ('mov')
  String get selectedCategory => _selectedCategory;

  /// 更新分类并通知监听者刷新视图
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }
}
