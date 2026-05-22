import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/data/data_manager.dart';
import 'dashboard_models.dart';
import 'dashboard_grid_engine.dart';

/// Simplified controller for Dashboard state and interactions.
/// Cleanly decoupled: depends exclusively on the centralized DataManager.
class DashboardController extends ChangeNotifier {
  final DataManager _dataManager;
  StreamSubscription<List<DashboardItemConfig>>? _subscription;

  DashboardController(this._dataManager) {
    _subscribeToDataManager();
  }

  List<DashboardItemConfig> _items = [];
  List<DashboardItemConfig> get items => _items;

  bool _isEditMode = false;
  bool get isEditMode => _isEditMode;

  String? _grabbedItemId;
  String? get grabbedItemId => _grabbedItemId;

  void _subscribeToDataManager() {
    _subscription = _dataManager.watchDashboardItems().listen((newItems) {
      // 🛡️ Interaction Gate (交互栅栏机制)：
      // 只有在没有抓取任何卡片进行拖拽/缩放时，才接收外部或后台SWR流式同步，防止正在交互的卡片重置
      if (_grabbedItemId == null) {
        _items = newItems;
        notifyListeners();
      }
    });
  }

  void setEditMode(bool value) {
    if (_isEditMode == value) return;
    _isEditMode = value;
    if (!_isEditMode) {
      _grabbedItemId = null;
      // 退出编辑模式时，安全保存最终布局到本地数据库
      _dataManager.saveDashboardLayout(_items);
    }
    notifyListeners();
  }

  void toggleGrabItem(String id) {
    if (_grabbedItemId == id) {
      _grabbedItemId = null;
      finalizeLayout(); // 摆放完毕，运行重力下拽沉降并安全落锁保存
    } else {
      _grabbedItemId = id;
    }
    notifyListeners();
  }

  /// Updates an item's position during drag or keyboard move.
  void updateItemPosition(String id, int newX, int newY) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _items[index];
    if (newX < 0) newX = 0;
    if (newY < 0) newY = 0;

    _items[index] = item.copyWith(x: newX, y: newY);
    
    // 实时触发碰撞下推排版物理
    _items = DashboardGridEngine.adjustLayout(_items, id);
    notifyListeners();
  }

  /// Updates an item's size during resize.
  void updateItemSpan(String id, int spanX, int spanY) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    if (spanX < 1) spanX = 1;
    if (spanY < 1) spanY = 1;

    _items[index] = _items[index].copyWith(spanX: spanX, spanY: spanY);

    // 实时触发碰撞下推排版物理
    _items = DashboardGridEngine.adjustLayout(_items, id);
    notifyListeners();
  }

  /// Finalizes any interaction and settles the layout.
  void finalizeLayout() {
    _items = DashboardGridEngine.applyGravity(_items);
    // 摆放落锁时，立刻将最终重力对齐后的排版写入本地持久化
    _dataManager.saveDashboardLayout(_items);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
