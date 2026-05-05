import 'package:flutter/material.dart';
import 'dashboard_models.dart';
import 'dashboard_grid_engine.dart';

/// Simplified controller for Dashboard state and interactions.
class DashboardController extends ChangeNotifier {
  List<DashboardItemConfig> _items = [];
  List<DashboardItemConfig> get items => _items;

  bool _isEditMode = false;
  bool get isEditMode => _isEditMode;

  /// ID of the item currently being dragged or resized.
  String? _activeItemId;
  String? get activeItemId => _activeItemId;

  void setEditMode(bool value) {
    if (_isEditMode == value) return;
    _isEditMode = value;
    notifyListeners();
  }

  void setItems(List<DashboardItemConfig> newItems) {
    _items = DashboardGridEngine.applyGravity(newItems);
    notifyListeners();
  }

  /// Updates an item's position during drag.
  void updateItemPosition(String id, int newX, int newY) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _items[index];
    // Check for boundaries (e.g., 0 <= x < gridColumns)
    if (newX < 0) newX = 0;
    if (newY < 0) newY = 0;

    _items[index] = item.copyWith(x: newX, y: newY);
    _activeItemId = id;
    
    // We apply gravity only on drag end for stability, 
    // or continuously if you want "live compaction".
    notifyListeners();
  }

  /// Updates an item's size during resize.
  void updateItemSpan(String id, int spanX, int spanY) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    if (spanX < 1) spanX = 1;
    if (spanY < 1) spanY = 1;

    _items[index] = _items[index].copyWith(spanX: spanX, spanY: spanY);
    _activeItemId = id;
    notifyListeners();
  }

  /// Finalizes any interaction and settles the layout.
  void finalizeLayout() {
    _items = DashboardGridEngine.applyGravity(_items);
    _activeItemId = null;
    notifyListeners();
  }
}
