import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local/local_config_store.dart';
import '../models/user_settings.dart';
import '../models/book_data.dart';
import '../../log/log.dart';

/// 📚 Audiobookshelf 有声书/播客专属数据仓 (Book Domain Repository)
class BookRepository {
  final LocalConfigStore _localStore;

  BookRepository(this._localStore);

  bool _isDisposed = false;

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
  }

  /// 全局唯一单例，由 DataManager 在初始化时注入绑定
  static late final BookRepository instance;

  Future<Map<String, String>> _getAuthHeaders() async {
    final settings = await _localStore.userSettings.readData();
    final token = settings.api.absApiKey;
    if (token.isEmpty) return {};
    return {
      'Authorization': 'Bearer $token',
    };
  }

  Future<String> _getBaseUrl() async {
    final settings = await _localStore.userSettings.readData();
    return settings.api.absBaseUrl;
  }

  /// 📡 验证 Audiobookshelf 服务器连通性
  Future<bool> pingServer() async {
    try {
      final baseUrl = await _getBaseUrl();
      if (baseUrl.isEmpty) return false;

      final headers = await _getAuthHeaders();
      if (headers.isEmpty) return false;

      final url = '$baseUrl/api/libraries';
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 4));
      
      return response.statusCode == 200;
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to ping Audiobookshelf server: $e');
      return false;
    }
  }

  /// 📁 获取所有媒体库 (Libraries)
  Future<List<BookLibrary>> fetchLibraries() async {
    try {
      final baseUrl = await _getBaseUrl();
      if (baseUrl.isEmpty) return [];

      final headers = await _getAuthHeaders();
      final url = '$baseUrl/api/libraries';
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final libraries = data['libraries'] as List<dynamic>? ?? [];
        return libraries.map((e) => BookLibrary.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to fetch libraries from Audiobookshelf: $e');
    }
    return [];
  }

  /// 📚 获取某个媒体库下的所有书目，支持自动折叠合集
  Future<List<BookItem>> fetchLibraryItems(String libraryId, {bool collapseSeries = true}) async {
    try {
      final baseUrl = await _getBaseUrl();
      if (baseUrl.isEmpty) return [];

      final headers = await _getAuthHeaders();
      final url = '$baseUrl/api/libraries/$libraryId/items${collapseSeries ? '?collapseseries=1' : ''}';
      
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        return results.map((e) => BookItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to fetch items for library $libraryId: $e');
    }
    return [];
  }

  /// 📚 获取单本书籍/单项详情
  Future<BookItem?> fetchItem(String itemId) async {
    try {
      final baseUrl = await _getBaseUrl();
      if (baseUrl.isEmpty) return null;

      final headers = await _getAuthHeaders();
      final url = '$baseUrl/api/items/$itemId';
      
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return BookItem.fromJson(data);
      }
    } catch (e) {
      Log.d(LogGroup.network, 'Failed to fetch item $itemId: $e');
    }
    return null;
  }

  /// 🖼️ 构建包含鉴权 token 的封面直链
  Future<String> getCoverArtUrl(String itemId) async {
    final settings = await _localStore.userSettings.readData();
    final baseUrl = settings.api.absBaseUrl;
    final token = settings.api.absApiKey;
    if (baseUrl.isEmpty || token.isEmpty) return '';
    
    // Audiobookshelf 支持直接在 URL 尾部带上 token 获取图片
    return '$baseUrl/api/items/$itemId/cover?token=$token';
  }
}
