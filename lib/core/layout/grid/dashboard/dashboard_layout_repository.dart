import 'package:superfocus/core/layout/grid/dashboard/dashboard_layout_models.dart';

abstract class LayoutRepository {
  Future<List<ModuleConfig>> loadLayout();

  void saveLayout(List<ModuleConfig> configs);

  Future<Map<String, bool>> loadDebugSettings();

  void saveDebugSettings(Map<String, bool> settings);
}
