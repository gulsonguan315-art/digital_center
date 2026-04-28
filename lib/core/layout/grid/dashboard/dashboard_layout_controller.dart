import 'package:flutter/material.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_grid_adapter.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_grid_metrics.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_layout_models.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_layout_repository.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_layout_state.dart';

class LayoutInteractionState extends ChangeNotifier {
  final Map<String, Offset> _dragPreviewOffsets = {};
  final Map<String, Size> _resizePreviewSizes = {};

  Offset? getDragOffset(String moduleId) => _dragPreviewOffsets[moduleId];
  Size? getResizeSize(String moduleId) => _resizePreviewSizes[moduleId];

  void setDragOffset(String moduleId, Offset offset) {
    _dragPreviewOffsets[moduleId] = offset;
    notifyListeners();
  }

  void setResizeSize(String moduleId, Size size) {
    _resizePreviewSizes[moduleId] = size;
    notifyListeners();
  }

  void clear(String moduleId) {
    _dragPreviewOffsets.remove(moduleId);
    _resizePreviewSizes.remove(moduleId);
    notifyListeners();
  }
}

class LayoutController extends ChangeNotifier {
  final LayoutState state;
  final LayoutRepository repository;
  final LayoutInteractionState interaction = LayoutInteractionState();

  LayoutController({required this.state, required this.repository}) {
    state.addListener(notifyListeners);
    interaction.addListener(_handleInteractionChange);
  }

  void _handleInteractionChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    state.removeListener(notifyListeners);
    interaction.removeListener(_handleInteractionChange);
    interaction.dispose();
    super.dispose();
  }

  void toggleEditMode() {
    final wasEditing = state.isEditMode;
    state.toggleEditMode();

    if (wasEditing && !state.isEditMode) {
      repository.saveLayout(state.configs);
    }
  }

  void removeModule(String moduleId) {
    state.removeModule(moduleId);
  }

  void addModule(ModuleConfig config) {
    state.addModule(config);
  }

  void toggleModule(String moduleId) {
    if (state.isModuleActive(moduleId)) {
      removeModule(moduleId);
    } else {
      final config = ModuleConfig(
        moduleId: moduleId,
        x: 0,
        y: 1000,
        spanX: 2,
        spanY: 2,
      );
      addModule(config);
    }
  }

  void onDragStart(String moduleId, Rect baseRect) {
    interaction.setDragOffset(moduleId, Offset(baseRect.left, baseRect.top));
    state.startInteraction(moduleId);
  }

  void onDragUpdate(String moduleId, Offset delta) {
    final current = interaction.getDragOffset(moduleId);
    if (current != null) {
      interaction.setDragOffset(moduleId, current + delta);
    }
  }

  void onDragEnd(
    String moduleId,
    Offset finalPixels,
    int columns, {
    required DashboardGridMetrics metrics,
  }) {
    final placement = DashboardGridAdapter.resolvePlacementFromPixels(
      finalPixels,
      metrics: metrics,
    );
    state.updatePosition(moduleId, placement.x, placement.y, columns);
    interaction.clear(moduleId);
    state.endInteraction();
  }

  void onResizeStart(String moduleId, Size baseSize) {
    interaction.setResizeSize(moduleId, baseSize);
    state.startInteraction(moduleId);
  }

  void onResizeUpdate(String moduleId, Offset delta, int columns) {
    final current = interaction.getResizeSize(moduleId);
    if (current != null) {
      interaction.setResizeSize(moduleId, current + delta);
    }
  }

  void onResizeEnd(
    String moduleId,
    Size finalSize,
    int columns, {
    required DashboardGridMetrics metrics,
  }) {
    final span = DashboardGridAdapter.resolveSpanFromSize(
      finalSize,
      columns: columns,
      metrics: metrics,
    );
    state.updateSpan(moduleId, span.spanX, span.spanY, columns);
    interaction.clear(moduleId);
    state.endInteraction();
  }
}
