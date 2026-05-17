import '../models/dashboard_item_config.dart';

/// Simulates communication with a remote cloud server (e.g., NAS, Alist, or Jellyfin).
/// Managed exclusively by the DataManager.
class RemoteApiClient {
  /// Mocks fetching the latest dashboard layout configuration from the cloud.
  Future<List<DashboardItemConfig>> fetchDashboardLayout() async {
    // Simulate typical network latency (200ms)
    await Future.delayed(const Duration(milliseconds: 200));

    // By default, mimics no cloud layout changes or network unreachable.
    // This allows the SWR engine to seamlessly fallback to local cache.
    throw Exception("Cloud layout synchronized: No overrides found.");
  }
}
