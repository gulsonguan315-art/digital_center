/// 大楼树状图配置文件 (Building Map)
/// 这是 UI 层唯一需要手动注册房间的地方。
///
/// ## 前缀语法速查
///
/// | 前缀    | 示例               | 含义                             | FocusScope  |
/// |---------|--------------------|----------------------------------|-------------|
/// | `/`     | `/客厅`            | 子房间（独立作用域）              | 独立         |
/// | `+`     | `+有氧区`          | Zone 分区（与父房间共享作用域）   | 共用父 Room  |
/// | `*名`   | `*餐桌`            | 静态叶子节点                      | 共用父 Room  |
/// | `*`     | `*`                | 动态叶子节点通配符                | 共用父 Room  |
/// | `->`    | `->空中花园`       | 静态传送门按钮（back 弹栈飞回）   | 共用父 Room  |
/// | `*->`   | `*->播放器`        | 动态传送门（`*` 节点统一传送）    | 共用父 Room  |

abstract class FocusSyntax {
  static const String dynamicPortal = '*->';
  static const String staticPortal = '->';
  static const String room = '/';
  static const String zone = '+';
  static const String staticNode = '*';
}

class BuildingMap {
  /// 根房间集合：这些房间是导航树的最顶层边界，不允许继续 Back。
  static const Set<String> roots = {'走廊'};

  static bool isRoot(String id) => roots.contains(id);

  /// 扁平树状图：每个房间是顶层 key，子项通过前缀声明类型。
  /// 父子关系由 `/` 和 `+` 前缀隐式表达，无需嵌套。
  static final Map<String, List<String>> structure = {
    '公共区域': ['/空中花园'],
    '空中花园': ['*秋千', '*花盆'],
    '走廊': ['/客厅', '/厨房', '/健身房', '/卧室'],
    '客厅': ['*餐桌', '*茶几', '*沙发'],
    '厨房': ['*灶台', '*冰箱', '->空中花园'],
    '健身房': ['+有氧区', '+力量区'],
    '有氧区': ['*'],
    '力量区': ['*'],
    '卧室': ['*大床', '*衣柜'],
  };

  // ---------------------------------------------------------------------------
  // 查询 API
  // ---------------------------------------------------------------------------

  // --- O(1) 缓存表 ---
  static final Map<String, String> _parentCache = {};
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

  static List<String> getMembers(String roomId) {
    final items = structure[roomId];
    if (items == null) return [];
    return items.map((item) => _normalizeMember(item)).toList();
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
}
