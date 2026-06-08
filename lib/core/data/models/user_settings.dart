/// 🌐 全局网络接口终端配置模型 (API Endpoints Configuration Model)
/// 统一管理应用内所有的第三方/自建 API 域名，支持局域网 IP (`192.168.x.x`)，实现内外网访问无缝切换。
///
/// 配置结构已分组，方便用户直接编辑 user_settings.json：
/// - "api"：通用/其他 API（如 poetry）
/// - "media"：Jellyfin 相关（包括设备标识）
/// - "gonic"：Gonic Subsonic 音乐服务
class ApiEndpoints {
  final String poetryBaseUrl;
  final String weatherBaseUrl; // 预留天气 API
  final String mediaBaseUrl;   // 预留多媒体 API（通用）

  // Gonic (音乐)
  final String gonicBaseUrl;
  final String gonicUsername;
  final String gonicPassword;

  // Jellyfin (影视媒体)
  final String jellyfinBaseUrl;
  final String jellyfinToken;
  final String jellyfinUserId;

  // Jellyfin 客户端设备标识（用于 X-Emby-Authorization，可配置，出现在 Jellyfin 设备列表中）
  final String jellyfinDeviceClient;   // 例如 "SuperFocus"
  final String jellyfinDeviceName;     // 例如 "Digital Center TV" （设备名字）
  final String jellyfinDeviceId;       // 例如 "digital_center_tv_v1"
  final String jellyfinDeviceVersion;  // 例如 "1.0.0"

  const ApiEndpoints({
    required this.poetryBaseUrl,
    this.weatherBaseUrl = '',
    this.mediaBaseUrl = '',
    this.gonicBaseUrl = 'http://192.168.0.2:4747',
    this.gonicUsername = 'gulson',
    this.gonicPassword = 'a130s339',
    this.jellyfinBaseUrl = '',
    this.jellyfinToken = '',
    this.jellyfinUserId = '',
    this.jellyfinDeviceClient = 'SuperFocus',
    this.jellyfinDeviceName = 'Digital Center TV',
    this.jellyfinDeviceId = 'digital_center_tv_v1',
    this.jellyfinDeviceVersion = '1.0.0',
  });

  factory ApiEndpoints.fromJson(Map<String, dynamic> json) {
    // 支持新分组结构（推荐，便于阅读）或旧版扁平结构（向后兼容）
    final apiSec = (json['api'] as Map<String, dynamic>?) ?? json;
    final mediaSec = (json['media'] as Map<String, dynamic>?) ?? json;
    final gonicSec = (json['gonic'] as Map<String, dynamic>?) ?? json;

    return ApiEndpoints(
      poetryBaseUrl: _sanitizeUrl(
        (apiSec['poetry_api_base'] ?? json['poetry_api_base']) as String? ?? 'https://poetry.gulson.cc',
      ),
      weatherBaseUrl: _sanitizeUrl((apiSec['weather_api_base'] ?? json['weather_api_base']) as String? ?? ''),
      mediaBaseUrl: _sanitizeUrl((apiSec['media_api_base'] ?? json['media_api_base']) as String? ?? ''),
      gonicBaseUrl: _sanitizeUrl(
        (gonicSec['gonic_api_base'] ?? json['gonic_api_base']) as String? ?? 'http://192.168.0.2:4747',
      ),
      gonicUsername: (gonicSec['gonic_username'] ?? json['gonic_username']) as String? ?? 'gulson',
      gonicPassword: (gonicSec['gonic_password'] ?? json['gonic_password']) as String? ?? 'a130s339',
      jellyfinBaseUrl: _sanitizeUrl(
        (mediaSec['jellyfin_api_base'] ?? json['jellyfin_api_base']) as String? ?? '',
      ),
      jellyfinToken:   (mediaSec['jellyfin_api_token'] ?? json['jellyfin_api_token']) as String? ?? '',
      jellyfinUserId:  (mediaSec['jellyfin_user_id'] ?? json['jellyfin_user_id']) as String? ?? '',
      // 设备名字相关（与 jellyfin_api_base 放在 media 组下）
      jellyfinDeviceClient: (mediaSec['jellyfin_device_client'] ?? json['jellyfin_device_client']) as String? ?? 'SuperFocus',
      jellyfinDeviceName:   (mediaSec['jellyfin_device_name'] ?? json['jellyfin_device_name']) as String? ?? 'Digital Center TV',
      jellyfinDeviceId:     (mediaSec['jellyfin_device_id'] ?? json['jellyfin_device_id']) as String? ?? 'digital_center_tv_v1',
      jellyfinDeviceVersion:(mediaSec['jellyfin_device_version'] ?? json['jellyfin_device_version']) as String? ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() => {
    // 为了让 user_settings.json 更清晰，将配置分组
    'api': {
      '_help': '通用 API 配置（poetry 等）',
      'poetry_api_base': poetryBaseUrl,
      'weather_api_base': weatherBaseUrl,
      'media_api_base': mediaBaseUrl,
    },
    'media': {
      '_help': 'Jellyfin 影视媒体配置（设备名字会显示在 Jellyfin「设备」列表中，和 jellyfin_api_base 放在一起）',
      'jellyfin_api_base': jellyfinBaseUrl,
      'jellyfin_api_token': jellyfinToken,
      'jellyfin_user_id': jellyfinUserId,
      'jellyfin_device_client': jellyfinDeviceClient,
      'jellyfin_device_name': jellyfinDeviceName,
      'jellyfin_device_id': jellyfinDeviceId,
      'jellyfin_device_version': jellyfinDeviceVersion,
    },
    'gonic': {
      '_help': 'Gonic Subsonic 音乐服务配置',
      'gonic_api_base': gonicBaseUrl,
      'gonic_username': gonicUsername,
      'gonic_password': gonicPassword,
    },
  };

  /// 默认内置公网域名配置 (Out-of-the-box Defaults)
  static const ApiEndpoints defaultEndpoints = ApiEndpoints(
    poetryBaseUrl: 'https://poetry.gulson.cc',
    gonicBaseUrl: 'http://192.168.0.2:4747',
    gonicUsername: 'gulson',
    gonicPassword: 'a130s339',
    // Jellyfin 设备默认名字
    jellyfinDeviceClient: 'SuperFocus',
    jellyfinDeviceName: 'Digital Center TV',
    jellyfinDeviceId: 'digital_center_tv_v1',
    jellyfinDeviceVersion: '1.0.0',
  );

  /// 🛡️ URL 自愈清洗器 (Automatic Url Sanitization Filter)
  /// 自动去除前后空格、尾部斜杠，并补齐缺少的 http/https 协议前缀，防止用户输入失误造成崩溃。
  static String _sanitizeUrl(String url) {
    var sanitized = url.trim();
    if (sanitized.isEmpty) return sanitized;

    // 1. 递归清洗尾部斜杠
    while (sanitized.endsWith('/')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }

    // 2. 补齐缺少的协议头
    if (!sanitized.startsWith('http://') && !sanitized.startsWith('https://')) {
      sanitized = 'http://$sanitized';
    }

    return sanitized;
  }
}

/// 综合用户配置模型
/// JSON 结构已分组（方便直接编辑 user_settings.json）：
/// - api：通用 API
/// - media：Jellyfin 影视 + 设备名字（jellyfin_device_name 等）
/// - gonic：Gonic 音乐服务
class UserSettings {
  final ApiEndpoints api;
  final String interactionMode;
  final bool immersiveMode;

  const UserSettings({
    required this.api, 
    this.interactionMode = 'focus',
    this.immersiveMode = false,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    // 直接把根 json 传给 ApiEndpoints，它内部会从 'api'/'media'/'gonic' 分组或旧扁平结构中提取
    return UserSettings(
      api: ApiEndpoints.fromJson(json),
      interactionMode: json['interactionMode'] as String? ?? 'focus',
      immersiveMode: json['immersiveMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    '_help_interactionMode': '【交互模式配置】支持 "focus" (遥控器纯焦点模式) 或 "mouse" (纯鼠标点击模式)',
    'interactionMode': interactionMode,
    '_help_immersiveMode': '【沉浸模式】true代表最大化无边框置顶，false代表普通窗口',
    'immersiveMode': immersiveMode,
    // 把 ApiEndpoints 产生的分组（api / media / gonic）展开到顶层，方便用户直接编辑
    ...api.toJson(),
  };

  static const UserSettings defaultSettings = UserSettings(
    api: ApiEndpoints.defaultEndpoints,
    interactionMode: 'focus',
    immersiveMode: false,
  );
}
