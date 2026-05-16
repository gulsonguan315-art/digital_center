import 'package:flutter/foundation.dart';

/// 测试页面的交互回调逻辑
class TestPageCallback {
  // 这里可以添加 ValueNotifier 或其他逻辑，目前仅作为职责对齐
  static void onNodePressed(String id) {
    debugPrint('Test Node Pressed: $id');
  }
}
