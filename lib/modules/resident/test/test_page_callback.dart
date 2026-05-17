import 'package:flutter/foundation.dart';

/// 模拟文件项
class MockFileItem {
  final String id;
  final String label;
  final bool isFolder;
  final List<MockFileItem>? children;

  const MockFileItem({
    required this.id,
    required this.label,
    this.isFolder = false,
    this.children,
  });
}

/// 测试页面的交互回调逻辑
class TestPageCallback {
  // --- 模拟递归数据源 ---
  static const List<MockFileItem> mockFileSystem = [
    MockFileItem(id: 'docs', label: 'Documents', isFolder: true, children: [
      MockFileItem(id: 'work', label: 'Work', isFolder: true, children: [
        MockFileItem(id: 'report.pdf', label: 'Annual_Report.pdf'),
        MockFileItem(id: 'notes.txt', label: 'Notes.txt'),
      ]),
      MockFileItem(id: 'personal', label: 'Personal', isFolder: true, children: [
        MockFileItem(id: 'todo.md', label: 'Todo_List.md'),
      ]),
    ]),
    MockFileItem(id: 'images', label: 'Images', isFolder: true, children: [
      MockFileItem(id: 'vacation.png', label: 'Vacation.png'),
      MockFileItem(id: 'avatar.jpg', label: 'Avatar.jpg'),
    ]),
    MockFileItem(id: 'config.yaml', label: 'Config.yaml'),
  ];

  /// 根据 ID 查找子项
  static List<MockFileItem> getItemsFor(String id) {
    if (id == 'explorer') return mockFileSystem;
    
    MockFileItem? find(List<MockFileItem> list, String targetId) {
      for (final item in list) {
        if (item.id == targetId) return item;
        if (item.children != null) {
          final found = find(item.children!, targetId);
          if (found != null) return found;
        }
      }
      return null;
    }
    
    return find(mockFileSystem, id)?.children ?? [];
  }

  static void onNodePressed(String id) {
    debugPrint('Test Node Pressed: $id');
  }
}
