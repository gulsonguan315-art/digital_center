import '../../models/user_settings.dart';
import 'local_json_store_base.dart';

/// 📂 全局用户配置专属子仓 (Dedicated User Settings Store)
/// 直接继承 `LocalJsonStoreBase` 泛型大底座，仅需 15 行即可实现完整的文件自愈读写和 Fallback。
class LocalUserSettingsStore extends LocalJsonStoreBase<UserSettings> {
  LocalUserSettingsStore({required super.configDirPath})
    : super(fileName: 'user_settings.json');

  @override
  UserSettings fromJson(Map<String, dynamic> json) =>
      UserSettings.fromJson(json);

  @override
  Map<String, dynamic> toJson(UserSettings data) => data.toJson();

  @override
  UserSettings get fallbackValue => UserSettings.defaultSettings;
}
