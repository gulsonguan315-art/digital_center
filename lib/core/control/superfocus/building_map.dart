/// 大楼树状图配置文件 (Building Map)
/// 这是 UI 层唯一需要手动注册房间的地方。
/// ## 前缀语法速查

/// | 前缀    | 示例               | 含义                             | FocusScope  |
/// |---------|--------------------|----------------------------------|-------------|
/// | `/`     | `/客厅`            | 子房间（独立作用域）              | 独立         |
/// | `+`     | `+有氧区`          | Zone 分区（与父房间共享作用域）   | 共用父 Room  |
/// | `*名`   | `*餐桌`            | 静态叶子节点                      | 共用父 Room  |
/// | `*`     | `*`                | 动态叶子节点通配符                | 共用父 Room  |
/// | `->`    | `->空中花园`       | 静态传送门按钮（back 弹栈飞回）   | 共用父 Room  |
/// | `*->`   | `*->播放器`        | 动态传送门（`*` 节点统一传送）    | 共用父   |

abstract class FocusSyntax {
  static const String navTarget = '=>';
  static const String dynamicPortal = '*->';
  static const String staticPortal = '->';
  static const String room = '/';
  static const String zone = '+';
  static const String staticNode = '*';
}

class BuildingMap {
  static const Set<String> roots = {'sidebar'}; // 还原为 sidebar

  static bool isRoot(String id) => roots.contains(id);

  static final Map<String, List<String>> structure = {
    'sidebar': [
      '*dashboard=>dashboardPage',
      '+media',
      '+music',
      '*setting=>settingPage',
      '*exit',
    ],
    'media': ['*mov', '*tv', '*ani', '*doc', '*adt'],

    'dashboardPage': [
      '*dash_weather',
      '*dash_music',
      '*dash_clock',
      '*dash_stats',
      '*dash_lights',
      '*dash_air_conditioner',
      '*dash_security',
      '*dash_energy',
    ],

    'settingPage': ['/color_mode'],
    'color_mode': ['*light_mode', '*night_mode'],

    'music': ['*宫', '*商', '*角', '*徵', '*羽'],

    '公共区域': ['/空中花园'],
    '空中花园': ['*秋千', '*花盆'],
    '走廊': ['/厨房', '/健身房'],
    '厨房': ['*灶台', '*冰箱', '->空中花园'],
    '健身房': ['+有氧区', '+力量区'],
    '有氧区': ['*'],
    '力量区': ['*'],
  };

  // ---------------------------------------------------------------------------
  // 查询 API
  // ---------------------------------------------------------------------------

  // --- O(1) 缓存表 ---
  static final Map<String, String> _parentCache = {};
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

  static bool isRoom(String id) => structure.containsKey(id);
  static bool isZone(String id) {
    _ensureInitialized();
    return _zoneCache.contains(id);
  }

  static String? getParentRoom(String id) {
    _ensureInitialized();
    return _parentCache[id];
  }

  static String? getEntryNodeForRoom(String parentRoomId, String targetRoomId) {
    _ensureInitialized();
    return _entryNodeCache[_entryNodeKey(parentRoomId, targetRoomId)];
  }

  static List<String> getMembers(String roomId) {
    final items = structure[roomId];
    if (items == null) return [];
    return items.map((item) => _normalizeMember(item)).toList();
  }

  static String? resolveNavTarget(String currentRoomId, String buttonId) {
    final items = structure[currentRoomId];
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
    final items = structure[currentRoomId];
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
    final items = structure[currentRoomId];
    if (items == null) return null;
    if (items.contains('${FocusSyntax.room}$buttonId') ||
        items.contains('${FocusSyntax.zone}$buttonId')) {
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
