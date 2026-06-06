import 'building_map_data.dart';
export 'building_map_data.dart';

class BuildingMap {
  static Set<String> get roots => BuildingMapData.roots;
  static Map<String, List<String>> get structure => BuildingMapData.structure;

  static bool isRoot(String id) => roots.contains(id);

  // ---------------------------------------------------------------------------
  // 查询 API
  // ---------------------------------------------------------------------------

  // --- O(1) 缓存表 ---
  static final Map<String, String> _parentCache = {};
  static final Map<String, String> _dynamicParentCache = {};
  static final Set<String> _terminalRoomsCache = {};
  static const int _maxDynamicCacheSize = 500;
  static final Map<String, String> _entryNodeCache = {};
  static final Set<String> _zoneCache = {};
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (_initialized) return;
    for (final MapEntry(key: parentId, value: items) in structure.entries) {
      for (final item in items) {
        if (item.startsWith(FocusSyntax.room)) {
          _parentCache[item.substring(FocusSyntax.room.length)] = parentId;
        } else if (item.startsWith(FocusSyntax.zone)) {
          final childId = item.substring(FocusSyntax.zone.length);
          _parentCache[childId] = parentId;
          _zoneCache.add(childId);
        } else {
          final link = _parseNavLink(item);
          if (link != null) {
            _parentCache[link.targetId] = parentId;
            _entryNodeCache[_entryNodeKey(parentId, link.targetId)] =
                link.sourceId;
          }
        }
      }
    }
    _initialized = true;
  }

  static bool isRoom(String id, {String? inRoomId}) {
    _ensureInitialized();
    if (structure.containsKey(id)) return true;

    // 如果已知父房间，检查父房间是否允许动态子房间
    if (inRoomId != null) {
      final items = _getEffectiveItems(inRoomId);
      if (items != null && items.contains(FocusSyntax.dynamicRoom)) {
        return true;
      }
    }

    // 检查是否已经动态注册过
    return _parentCache.containsKey(id) || _dynamicParentCache.containsKey(id);
  }

  static bool isZone(String id) {
    _ensureInitialized();
    return _zoneCache.contains(id);
  }

  static String? getParentRoom(String id) {
    _ensureInitialized();
    return _parentCache[id] ?? _dynamicParentCache[id];
  }

  /// 动态注册父子关系（用于动态生成的文件夹/房间）
  /// [asTerminalRoom] - 标记为终端叶子房间，阻断继承父级的通配符结构
  static void registerDynamicParent(
    String childId,
    String parentId, {
    bool asTerminalRoom = false,
  }) {
    _ensureInitialized();
    if (_parentCache.containsKey(childId)) return;

    // LRU 策略：更新最近使用顺序
    _dynamicParentCache.remove(childId);
    _dynamicParentCache[childId] = parentId;

    if (asTerminalRoom) {
      _terminalRoomsCache.add(childId);
    } else {
      _terminalRoomsCache.remove(childId);
    }

    // 容量控制，防止缓慢的内存泄漏
    if (_dynamicParentCache.length > _maxDynamicCacheSize) {
      final oldest = _dynamicParentCache.keys.first;
      _dynamicParentCache.remove(oldest);
      _terminalRoomsCache.remove(oldest);
    }
  }

  static void clearDynamicCache() {
    _dynamicParentCache.clear();
    _terminalRoomsCache.clear();
  }

  static String? getEntryNodeForRoom(String parentRoomId, String targetRoomId) {
    _ensureInitialized();
    return _entryNodeCache[_entryNodeKey(parentRoomId, targetRoomId)];
  }

  /// 运行时动态更新「入口节点」缓存。
  /// 用于多个 NavTarget 指向同一目标房间时，记录实际触发的那个按钮 ID，
  /// 以便 Back 时能精确回落到发起导航的那个节点。
  static void updateEntryNode(
    String parentRoomId,
    String targetRoomId,
    String nodeId,
  ) {
    _ensureInitialized();
    _entryNodeCache[_entryNodeKey(parentRoomId, targetRoomId)] = nodeId;
  }

  /// 获取房间的有效成员列表（支持递归继承）
  static List<String>? _getEffectiveItems(String roomId) {
    // 1. 尝试获取显式定义的成员
    final items = structure[roomId];
    if (items != null) return items;

    // 2. 尝试从父房间继承通配符结构
    final parentId = getParentRoom(roomId);
    if (parentId != null) {
      final parentItems = _getEffectiveItems(parentId);
      // 如果父级包含 /* 通配符，则子级继承该结构
      if (parentItems != null &&
          parentItems.contains(FocusSyntax.dynamicRoom)) {
        return parentItems;
      }
    }
    return null;
  }

  static List<String> getMembers(String roomId) {
    final items = _getEffectiveItems(roomId);
    if (items == null) return [];
    return items.map((item) => _normalizeMember(item)).toList();
  }

  static String? resolveNavTarget(String currentRoomId, String buttonId) {
    final items = _getEffectiveItems(currentRoomId);
    if (items == null) return null;
    for (final item in items) {
      final link = _parseNavLink(item);
      if (link != null && link.sourceId == buttonId) return link.targetId;
    }
    return null;
  }

  static String? resolvePortalDestination(
    String currentRoomId,
    String buttonId,
  ) {
    final items = _getEffectiveItems(currentRoomId);
    if (items == null) return null;
    if (items.contains('${FocusSyntax.staticPortal}$buttonId')) return buttonId;
    for (final item in items) {
      if (item.startsWith(FocusSyntax.dynamicPortal)) {
        final destination = item.substring(FocusSyntax.dynamicPortal.length);
        final isStaticId = items.any(
          (i) =>
              i == '${FocusSyntax.staticNode}$buttonId' ||
              i == '${FocusSyntax.room}$buttonId' ||
              i == '${FocusSyntax.zone}$buttonId',
        );
        if (!isStaticId) return destination;
      }
    }
    return null;
  }

  static String? resolveRoomEntry(String currentRoomId, String buttonId) {
    final items = _getEffectiveItems(currentRoomId);
    if (items == null) return null;

    // 静态匹配：/id 或 +id
    if (items.contains('${FocusSyntax.room}$buttonId') ||
        items.contains('${FocusSyntax.zone}$buttonId')) {
      return buttonId;
    }

    // 动态匹配：如果当前房间支持动态子房间 (/*)，且不是终端房间
    if (items.contains(FocusSyntax.dynamicRoom) &&
        !_terminalRoomsCache.contains(currentRoomId)) {
      return buttonId;
    }

    return null;
  }

  // 内部工具
  static String _normalizeMember(String item) {
    final navTargetIndex = item.indexOf(FocusSyntax.navTarget);
    if (navTargetIndex >= 0) {
      item = item.substring(0, navTargetIndex);
    }

    return switch (item) {
      _ when item.startsWith(FocusSyntax.dynamicPortal) =>
        FocusSyntax.staticNode,
      _ when item.startsWith(FocusSyntax.staticPortal) => item.substring(
        FocusSyntax.staticPortal.length,
      ),
      _ when item == FocusSyntax.staticNode => FocusSyntax.staticNode,
      _
          when item.startsWith(FocusSyntax.room) ||
              item.startsWith(FocusSyntax.zone) ||
              item.startsWith(FocusSyntax.staticNode) =>
        item.substring(1),
      _ => item,
    };
  }

  static _NavLink? _parseNavLink(String item) {
    if (!item.startsWith(FocusSyntax.staticNode) ||
        !item.contains(FocusSyntax.navTarget)) {
      return null;
    }

    final normalizedItem = item.substring(FocusSyntax.staticNode.length);
    final targetIndex = normalizedItem.indexOf(FocusSyntax.navTarget);
    final sourceId = normalizedItem.substring(0, targetIndex);
    final targetId = normalizedItem.substring(
      targetIndex + FocusSyntax.navTarget.length,
    );

    if (sourceId.isEmpty || targetId.isEmpty) return null;
    return _NavLink(sourceId, targetId);
  }

  static String _entryNodeKey(String parentRoomId, String targetRoomId) =>
      '$parentRoomId=>$targetRoomId';
}

class _NavLink {
  final String sourceId;
  final String targetId;

  const _NavLink(this.sourceId, this.targetId);
}
