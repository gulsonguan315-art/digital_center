import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/dashboard_item_config.dart';
import '../models/poetry_data.dart';

/// Simulates communication with a remote cloud server (e.g., NAS, Alist, or Jellyfin).
/// Managed exclusively by the DataManager.
class RemoteApiClient {
  /// The base URL for the poetry API server.
  /// Can be overridden dynamically by DataManager loading from a local config file.
  String apiBaseUrl = 'https://poetry.gulson.cc';

  /// Mocks fetching the latest dashboard layout configuration from the cloud.
  Future<List<DashboardItemConfig>> fetchDashboardLayout() async {
    // Simulate typical network latency (200ms)
    await Future.delayed(const Duration(milliseconds: 200));

    // By default, mimics no cloud layout changes or network unreachable.
    // This allows the SWR engine to seamlessly fallback to local cache.
    throw Exception("Cloud layout synchronized: No overrides found.");
  }

  /// Fetches today's classical poetry from the remote server endpoint.
  Future<PoetryData> fetchTodayPoetry() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/api/poetry/today'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        // Decode body using UTF-8 explicitly to guarantee Chinese characters display correctly
        final content = utf8.decode(response.bodyBytes);
        final json = jsonDecode(content) as Map<String, dynamic>;
        return PoetryData.fromJson(json);
      }
      throw Exception('API Server returned error: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  /// Sends the highlighted lines list to the remote server to persist.
  /// Points natively to POST /api/poetry/mark/{poem_id}
  Future<void> uploadPoemMark(String poemId, List<int> markedLines) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/api/poetry/mark/$poemId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'marked_lines': markedLines}),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw Exception(
          'Server failed to persist marks: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
