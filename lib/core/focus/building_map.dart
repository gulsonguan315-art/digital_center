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

  /// 某个 ID 是否在地图中定义为房间/Zone（即作为 key 存在）。
  static bool isRoom(String id) => structure.containsKey(id);

  /// 某个 ID 是否被声明为 Zone（父房间列表中有 `+$id`）。
  static bool isZone(String id) {
    return structure.values.any((list) => list.contains('+$id'));
  }

  /// 获取某房间/Zone 的直接父房间 ID。
  /// 扫描所有房间列表，找包含 `/$id` 或 `+$id` 的那个。
  static String? getParentRoom(String id) {
    for (final entry in structure.entries) {
      for (final item in entry.value) {
        if (item == '/$id' || item == '+$id') return entry.key;
      }
    }
    return null;
  }

  /// 获取某房间的所有成员 ID（已归一化，去掉前缀）。
  /// `*->X` 归一化为 `*`（视为动态节点）。
  static List<String> getMembers(String roomId) {
    final items = structure[roomId];
    if (items == null) return [];
    return items.map((item) => _normalizeMember(item)).toList();
  }

  /// [虫洞传送] 检查当前房间是否允许通过 buttonId 传送到另一个房间。
  /// 仅 `->X` 或 `*->X`（动态节点）才授权，返回目标房间 ID。
  static String? resolvePortalDestination(
    String currentRoomId,
    String buttonId,
  ) {
    final items = structure[currentRoomId];
    if (items == null) return null;

    // 静态传送门：->buttonId
    if (items.contains('->$buttonId')) return buttonId;

    // 动态传送门：*->X，当前按下的是 * 节点（ID 不在静态列表中）
    for (final item in items) {
      if (item.startsWith('*->')) {
        final destination = item.substring(3);
        final isStaticId = items.any(
          (i) => i == '*$buttonId' || i == '/$buttonId' || i == '+$buttonId',
        );
        if (!isStaticId) return destination;
      }
    }
    return null;
  }

  /// [普通推门] 检查 buttonId 是否为当前房间的直接子房间或子 Zone。
  static String? resolveRoomEntry(String currentRoomId, String buttonId) {
    final items = structure[currentRoomId];
    if (items == null) return null;
    if (items.contains('/$buttonId') || items.contains('+$buttonId')) {
      return buttonId;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  /// 将列表项归一化为节点 ID（去掉前缀）。
  /// `*->X` → `*`（动态节点，目标在 resolvePortalDestination 里解析）
  static String _normalizeMember(String item) {
    if (item.startsWith('*->')) return '*'; // 动态传送门 → 通配符
    if (item.startsWith('->')) return item.substring(2); // 静态传送门按钮 ID
    if (item.startsWith('/') || item.startsWith('+') || item.startsWith('*')) {
      return item.substring(1); // 子房间 / Zone / 静态项
    }
    return item;
  }
}
