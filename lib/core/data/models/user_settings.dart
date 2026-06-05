/// 🌐 全局网络接口终端配置模型 (API Endpoints Configuration Model)
/// 统一管理应用内所有的第三方/自建 API 域名，支持局域网 IP (`192.168.x.x`)，实现内外网访问无缝切换。
class ApiEndpoints {
  final String poetryBaseUrl;
  final String weatherBaseUrl; // 预留天气 API
  final String mediaBaseUrl;   // 预留多媒体 API（通用）
  final String gonicBaseUrl;
  final String gonicUsername;
  final String gonicPassword;
  final String jellyfinBaseUrl; // Jellyfin API 根地址
  final String jellyfinToken;   // Jellyfin API Token
  final String jellyfinUserId;  // Jellyfin 用户 ID

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
  });

  factory ApiEndpoints.fromJson(Map<String, dynamic> json) {
    return ApiEndpoints(
      poetryBaseUrl: _sanitizeUrl(
        json['poetry_api_base'] as String? ?? 'https://poetry.gulson.cc',
      ),
      weatherBaseUrl: _sanitizeUrl(json['weather_api_base'] as String? ?? ''),
      mediaBaseUrl: _sanitizeUrl(json['media_api_base'] as String? ?? ''),
      gonicBaseUrl: _sanitizeUrl(
        json['gonic_api_base'] as String? ?? 'http://192.168.0.2:4747',
      ),
      gonicUsername: json['gonic_username'] as String? ?? 'gulson',
      gonicPassword: json['gonic_password'] as String? ?? 'a130s339',
      jellyfinBaseUrl: _sanitizeUrl(
        json['jellyfin_api_base'] as String? ?? '',
      ),
      jellyfinToken:   json['jellyfin_api_token'] as String? ?? '',
      jellyfinUserId:  json['jellyfin_user_id']   as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'poetry_api_base': poetryBaseUrl,
    'weather_api_base': weatherBaseUrl,
    'media_api_base': mediaBaseUrl,
    'gonic_api_base': gonicBaseUrl,
    'gonic_username': gonicUsername,
    'gonic_password': gonicPassword,
    'jellyfin_api_base': jellyfinBaseUrl,
    'jellyfin_api_token': jellyfinToken,
    'jellyfin_user_id': jellyfinUserId,
  };

  /// 默认内置公网域名配置 (Out-of-the-box Defaults)
  static const ApiEndpoints defaultEndpoints = ApiEndpoints(
    poetryBaseUrl: 'https://poetry.gulson.cc',
    gonicBaseUrl: 'http://192.168.0.2:4747',
    gonicUsername: 'gulson',
    gonicPassword: 'a130s339',
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

/// 综合用户配置模型，分块存储 api 及交互模式
class UserSettings {
  final ApiEndpoints api;
  final String interactionMode;

  const UserSettings({required this.api, this.interactionMode = 'focus'});

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      api: json['api'] != null
          ? ApiEndpoints.fromJson(json['api'] as Map<String, dynamic>)
          : ApiEndpoints.defaultEndpoints,
      interactionMode: json['interactionMode'] as String? ?? 'focus',
    );
  }

  Map<String, dynamic> toJson() => {
    '_help_interactionMode': '【交互模式配置】支持 "focus" (遥控器纯焦点模式) 或 "mouse" (纯鼠标点击模式)',
    'interactionMode': interactionMode,
    'api': api.toJson(),
  };

  static const UserSettings defaultSettings = UserSettings(
    api: ApiEndpoints.defaultEndpoints,
    interactionMode: 'focus',
  );
}
