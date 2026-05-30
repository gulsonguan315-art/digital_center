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
  static const String dynamicRoom = '/*';
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
      '*music=>musicPage',
      '+book',
      '*setting=>settingPage',
      '*exit',
    ],

    'media': ['*mov', '*tv', '*ani', '*doc', '*adt'],
    'book': ['*科幻', '*人文=>testPage'],

    'musicPage': [
      '/music_folder',
      '/music_list',
      '/music_lyrics',
      '/music_control',
    ],
    'music_folder': ['*'],
    'music_list': ['*'],
    'music_lyrics': [
      '*music_lyrics_offset_minus',
      '*music_lyrics_offset_minus_small',
      '*music_lyrics_offset_plus_small',
      '*music_lyrics_offset_plus',
      '*music_lyrics_export',
    ],
    'music_control': [
      '*music_play', // 置于首位，进入房间时默认获取焦点
      '*music_play_mode',
      '*music_fast_rewind',
      '*music_prev',
      '*music_next',
      '*music_fast_forward',
      '*music_fullscreen=>music_overlay',
    ],

    'music_overlay': ['*style_mood', '*style_scrolling', '*style_single_line'],

    'dashboardPage': [
      '*dash_weather',
      '*dash_music',
      '*dash_clock',
      '*dash_stats',
      '*dash_lights',
      '*dash_air_conditioner',
      '*dash_security',
      '*dash_energy',
      '*dash_poetry=>poetry_overlay', // 🌟 注册静态导航跳转链接到古诗沉浸空间
      '/dash_widget_manager', // 🌟 挂件中控直接作为一个子房间
    ],

    'settingPage': ['/theme_setting', '/custom_setting', '/log_setting'],

    'theme_setting': ['+color_mode', '+visual_mode', '+shape_mode'],
    'color_mode': ['*light_mode', '*night_mode'],
    'visual_mode': ['*flat', '*glassy', '*neumorphic'],
    'shape_mode': ['*rightangle', '*round', '*soft'],

    'custom_setting': ['*setting_a', '*setting_b', '*setting_c'],

    'log_setting': ['*log_focus', '*log_network', '*log_ui', '*log_system'],

    'testPage': ['*card1', '/explorer'],
    'explorer': ['/*', '*'],
    'poetry_overlay': ['*'], // 🌟 注册沉浸 Overlay 房间，使用通配符以动态支持行点击高亮
    'dash_widget_manager': ['*'], // 🌟 挂件中控房间，支持内部元素进行焦点交互

    'work_setting': ['*work_a', '*work_b', '/work_grop'],
    'work_grop': ['*work_c', '*work_d'],

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

  static String? getEntryNodeForRoom(String parentRoomId, String targetRoomId) {
    _ensureInitialized();
    return _entryNodeCache[_entryNodeKey(parentRoomId, targetRoomId)];
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

    // 动态匹配：如果当前房间支持动态子房间 (/*)
    if (items.contains(FocusSyntax.dynamicRoom)) {
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
