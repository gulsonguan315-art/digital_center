import '../../models/system_settings.dart';
import 'local_json_store_base.dart';

/// 📂 系统设置偏好专属子仓 (Dedicated Settings Sub-store)
/// 独立负责系统偏好配置（亮暗模式、视觉特效、直角形状、日志组开关）的数据持久化。
class LocalSettingsStore extends LocalJsonStoreBase<SystemSettings> {
  LocalSettingsStore({required super.configDirPath})
      : super(fileName: 'system_settings.json');

  /// 适配大管家历史调用 API (Backward Compatibility Proxies)
  Future<SystemSettings> readSystemSettings() => readData();
  Future<void> writeSystemSettings(SystemSettings settings) => writeData(settings);

  @override
  SystemSettings fromJson(Map<String, dynamic> json) => SystemSettings.fromJson(json);

  @override
  Map<String, dynamic> toJson(SystemSettings data) => data.toJson();

  @override
  SystemSettings get fallbackValue => SystemSettings.defaultSettings;
}
