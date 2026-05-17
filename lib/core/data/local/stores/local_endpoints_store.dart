import '../../models/api_endpoints.dart';
import 'local_json_store_base.dart';

/// 📂 全局 API 接口终端配置专属子仓 (Dedicated API Endpoints Store)
/// 直接继承 `LocalJsonStoreBase` 泛型大底座，仅需 15 行即可实现完整的文件自愈读写和 Fallback。
class LocalEndpointsStore extends LocalJsonStoreBase<ApiEndpoints> {
  LocalEndpointsStore({required super.configDirPath})
      : super(fileName: 'api_endpoints.json');

  @override
  ApiEndpoints fromJson(Map<String, dynamic> json) => ApiEndpoints.fromJson(json);

  @override
  Map<String, dynamic> toJson(ApiEndpoints data) => data.toJson();

  @override
  ApiEndpoints get fallbackValue => ApiEndpoints.defaultEndpoints;
}
