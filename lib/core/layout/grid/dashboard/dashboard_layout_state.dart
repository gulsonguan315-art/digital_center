import 'package:flutter/foundation.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_grid_engine.dart';
import 'package:superfocus/core/layout/grid/dashboard/dashboard_layout_models.dart';

class LayoutState extends ChangeNotifier {
  static int _instanceCount = 0;
  final int instanceId = ++_instanceCount;

  bool _isEditMode = false;
  bool get isEditMode => _isEditMode;

  List<ModuleConfig> _configs = [];
  List<ModuleConfig> get configs => _configs;

  String? _activeModuleId;
  String? get activeModuleId => _activeModuleId;

  bool isModuleActive(String moduleId) {
    return _configs.any((c) => c.moduleId == moduleId);
  }

  void init(List<ModuleConfig> initialConfigs) {
    print("LayoutState: Loaded ${configs.length} modules");
    _configs = DashboardGridEngine.applyGravity(
      initialConfigs,
      updateY: (config, newY) => config.copyWith(y: newY),
    );
    notifyListeners();
  }

  void addModule(ModuleConfig config) {
    print("LayoutState: Adding module ${config.moduleId}");
    _configs = [..._configs, config];
    _configs = DashboardGridEngine.applyGravity(
      _configs,
      updateY: (c, newY) => c.copyWith(y: newY),
    );
    notifyListeners();
  }

  void removeModule(String moduleId) {
    print("LayoutState: Removing module $moduleId");
    _configs = _configs.where((c) => c.moduleId != moduleId).toList();
    _configs = DashboardGridEngine.applyGravity(
      _configs,
      updateY: (c, newY) => c.copyWith(y: newY),
    );
    notifyListeners();
  }

  void resetToDefault(List<ModuleConfig> defaultConfigs) {
    print("LayoutState: Resetting to default layout");
    init(defaultConfigs);
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    print("LayoutState(#$instanceId): toggleEditMode -> $_isEditMode");
    notifyListeners();
  }

  void startInteraction(String moduleId) {
    _activeModuleId = moduleId;
    notifyListeners();
  }

  void endInteraction() {
    _activeModuleId = null;
    _configs = DashboardGridEngine.applyGravity(
      _configs,
      updateY: (config, newY) => config.copyWith(y: newY),
    );
    notifyListeners();
  }

  void updatePosition(String moduleId, int x, int y, int columns) {
    ModuleConfig? current;
    for (final config in _configs) {
      if (config.moduleId == moduleId) {
        current = config;
        break;
      }
    }
    if (current == null) return;

    final maxX = (columns - current.spanX).clamp(0, 1000).toInt();
    final targetX = x.clamp(0, maxX).toInt();
    final targetY = y.clamp(0, 1000).toInt();

    final hasCollision = DashboardGridEngine.checkCollision(
      moduleId,
      targetX,
      targetY,
      current.spanX,
      current.spanY,
      _configs,
    );
    if (hasCollision) return;

    _configs = _configs.map((c) {
      if (c.moduleId == moduleId) {
        return c.copyWith(x: targetX, y: targetY);
      }
      return c;
    }).toList();

    _configs = DashboardGridEngine.applyGravity(
      _configs,
      updateY: (config, newY) => config.copyWith(y: newY),
    );
    notifyListeners();
  }

  void updateSpan(String moduleId, int spanX, int spanY, int columns) {
    ModuleConfig? current;
    for (final config in _configs) {
      if (config.moduleId == moduleId) {
        current = config;
        break;
      }
    }
    if (current == null) return;

    final maxSpanX = columns.clamp(1, 1000).toInt();
    final targetSpanX = spanX.clamp(1, maxSpanX).toInt();
    final targetSpanY = spanY.clamp(1, 1000).toInt();
    final maxX = (columns - targetSpanX).clamp(0, 1000).toInt();
    final targetX = current.x.clamp(0, maxX).toInt();

    final hasCollision = DashboardGridEngine.checkCollision(
      moduleId,
      targetX,
      current.y,
      targetSpanX,
      targetSpanY,
      _configs,
    );
    if (hasCollision) return;

    _configs = _configs.map((c) {
      if (c.moduleId == moduleId) {
        return c.copyWith(x: targetX, spanX: targetSpanX, spanY: targetSpanY);
      }
      return c;
    }).toList();

    _configs = DashboardGridEngine.applyGravity(
      _configs,
      updateY: (config, newY) => config.copyWith(y: newY),
    );
    notifyListeners();
  }
}
