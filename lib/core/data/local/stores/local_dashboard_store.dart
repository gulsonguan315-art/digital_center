import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../models/dashboard_item_config.dart';
import '../../../../core/data/models/dashboard_card_definition.dart';
import '../../../../modules/resident/dashboard/engine/dashboard_grid_engine.dart';

/// Top-level layout serialization helper for background Isolate execution.
String _encodeItems(List<DashboardItemConfig> items) {
  return jsonEncode(items.map((e) => e.toJson()).toList());
}

/// Top-level layout deserialization helper for background Isolate execution.
List<dynamic> _decodeContent(String content) {
  return jsonDecode(content) as List<dynamic>;
}

/// 📂 磁贴布局专属子仓 (Dedicated Layout Sub-store)
/// 独立负责看板卡片网格位置、大小的数据持久化，与其它业务数据彻底隔离。
class LocalDashboardStore {
  final String configDirPath;

  LocalDashboardStore({required this.configDirPath});

  static List<DashboardItemConfig> get _defaultItems =>
      DashboardRegistry.defaultItems;

  final _dashboardController =
      StreamController<List<DashboardItemConfig>>.broadcast();

  Timer? _writeTimer;
  List<DashboardItemConfig>? _pendingItems;

  String get _filePath => '$configDirPath/dashboard_layout.json';

  /// Exposes a responsive stream monitoring local dashboard card changes.
  Stream<List<DashboardItemConfig>> watchDashboardItems() =>
      _dashboardController.stream;

  /// Reads items from the disk. Offloads heavy JSON decoding to a background Isolate.
  Future<List<DashboardItemConfig>> readDashboardItems() async {
    if (kIsWeb) {
      return _defaultItems;
    }
    try {
      final file = File(_filePath);
      if (!file.existsSync()) {
        await writeDashboardItemsDebounced(_defaultItems);
        return _defaultItems;
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        await writeDashboardItemsDebounced(_defaultItems);
        return _defaultItems;
      }

      // 🚀 Isolate-based JSON parsing: Offload decoding from UI thread
      final List<dynamic> decoded = await compute(_decodeContent, content);
      final List<DashboardItemConfig> items = decoded
          .map((e) => DashboardItemConfig.fromJson(e as Map<String, dynamic>))
          .toList();

      // 🛡️ Clean up and Failsafe Migration: Dynamically keep only registered cards
      final List<String> activeIds = DashboardRegistry.activeCardIds;
      final List<DashboardItemConfig> filteredItems = items
          .where((e) => activeIds.contains(e.id))
          .toList();

      bool migrated = filteredItems.length != items.length;

      // Ensure all active registered cards exist. If not, append them with their default configs
      for (final card in DashboardRegistry.definitions) {
        if (!filteredItems.any((e) => e.id == card.id)) {
          filteredItems.add(card.defaultConfig);
          migrated = true;
        }
      }

      if (migrated) {
        // Run grid engine's gravity alignment to resolve any potential layout overlaps
        final resolvedItems = DashboardGridEngine.applyGravity(filteredItems);
        await writeDashboardItemsDebounced(resolvedItems);
        return resolvedItems;
      }
      return filteredItems;
    } catch (e) {
      return _defaultItems;
    }
  }

  /// Writes grid configurations to disk with high-frequency debouncing to avoid I/O conflict.
  /// Offloads JSON encoding to a background Isolate.
  Future<void> writeDashboardItemsDebounced(
    List<DashboardItemConfig> items,
  ) async {
    // 1. Snappiness First: Immediately emit events to UI streams for maximum responsiveness
    _dashboardController.add(items);

    if (kIsWeb) return;

    // 2. Buffer state in memory
    _pendingItems = items;

    // 3. Debounce Disk I/O: Merge high-frequency saves (e.g., keyboard dragging) in 300ms window
    _writeTimer?.cancel();
    _writeTimer = Timer(const Duration(milliseconds: 300), () async {
      final itemsToSave = _pendingItems;
      if (itemsToSave == null) return;

      try {
        final file = File(_filePath);
        // 🚀 Isolate-based JSON encoding: Offload encoding from UI thread
        final encoded = await compute(_encodeItems, itemsToSave);
        await file.writeAsString(encoded, flush: true);
      } catch (e) {
        // Silent catch for OS disk write stability
      }
    });
  }

  bool _isDisposed = false;

  /// 仅同步刷盘挂起的防抖写请求，但不关闭 Stream，以便应用在进入后台时保存数据且能够继续使用
  void flush() {
    if (kIsWeb) return;
    if (_writeTimer != null && _writeTimer!.isActive) {
      _writeTimer?.cancel();
      final itemsToSave = _pendingItems;
      if (itemsToSave != null) {
        try {
          final file = File(_filePath);
          final encoded = jsonEncode(
            itemsToSave.map((e) => e.toJson()).toList(),
          );
          file.writeAsStringSync(encoded, flush: true);
        } catch (e) {
          // Silent catch for OS disk write stability
        }
      }
    }
  }

  /// Transaction-safe teardown: synchronous flush of any pending writes during application shutdown.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    flush();
    _dashboardController.close();
  }
}
