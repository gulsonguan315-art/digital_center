import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'scoped_2d_scanner.dart';
import 'building_map.dart';

/// 焦点系统"黑盒"大脑
class SuperFocusManager {
  static final SuperFocusManager instance = SuperFocusManager._internal();
  SuperFocusManager._internal();

  // 1. 当前激活的房间 ID 监听器
  final ValueNotifier<String?> activeRoomNotifier = ValueNotifier<String?>(
    null,
  );

  // 2. 当前激活的房间路径（包含所有父级房间，用于级联状态）
  final ValueNotifier<Set<String>> activeRoomPathNotifier =
      ValueNotifier<Set<String>>({});

  // 获取当前房 ID 的简易写法
  String? get currentRoomId => activeRoomNotifier.value;

  final Scoped2dScanner scanner = const Scoped2dScanner();

  // 全局节点表：ID -> 节点信息
  final Map<String, _NodeInfo> _nodeRegistry = {};

  // --- 航道治理系统 (Handshake Protocol) ---
  // 记录"意图"：用户想去但还没落地的房间 ID
  final ValueNotifier<String?> intentionRoomId = ValueNotifier(null);

  // 记录跳转源头，用于日志追溯
  String? _lastActionSource;

  // PostFrameCallback 去重标记：同一帧内只安排一次回调
  bool _pendingCallback = false;

  // 传送门历史栈：记录每次 -> 跳转的落点和回源
  final List<_PortalEntry> _portalStack = [];

  /// 手动取消当前正在进行的跳转意图
  void cancelNavigation() {
    if (intentionRoomId.value != null) {
      print('⏹️ 导航意图已取消：[${intentionRoomId.value}]');
      intentionRoomId.value = null;
      // 传送门跳转在 onAction 中已压栈，若导航被取消则同步弹出
      if (_portalStack.isNotEmpty) _portalStack.removeLast();
    }
  }

  /// 注册节点
  void registerNode(String id, FocusNode node, String roomId) {
    _nodeRegistry[id] = _NodeInfo(node, roomId);

    // 🔥 极简揭榜：如果当前这件家具入场，且它所在的房间正在被通缉
    _tryFulfillIntention();
  }

  /// [赏金猎人] 核心撮合逻辑：尝试将当前意图与内存中的物理节点进行对冲
  void _tryFulfillIntention() {
    final target = intentionRoomId.value;
    if (target == null) return;

    // 同一帧内多个节点同时注册时，只安排一次 PostFrameCallback
    if (_pendingCallback) return;
    _pendingCallback = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingCallback = false;
      if (intentionRoomId.value == target) {
        _executeSearch(target);
      }
    });
  }

  /// 注销节点
  void unregisterNode(String id) {
    _nodeRegistry.remove(id);
  }

  /// 全局按键拦截器
  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (intentionRoomId.value != null) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          cancelNavigation();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 当进入一个房间时触发
  String? onRoomEnter(String roomId, {bool printLog = true}) {
    if (activeRoomNotifier.value != roomId) {
      final oldPath = activeRoomPathNotifier.value;
      activeRoomNotifier.value = roomId;

      // 新版 _fillPath：基于扁平 BuildingMap 的 getParentRoom 向上追溯祖先链
      final newPath = <String>{};
      _fillAncestorPath(roomId, newPath);
      activeRoomPathNotifier.value = newPath;

      final deactivated = oldPath.difference(newPath);
      final activated = newPath.difference(oldPath);

      if (deactivated.isNotEmpty || activated.isNotEmpty) {
        final buffer = StringBuffer();
        if (deactivated.isNotEmpty) buffer.writeln('状态熄灭：$deactivated');
        if (activated.isNotEmpty) buffer.writeln('状态激活：$activated');

        final result = buffer.toString().trim();
        if (printLog) {
          print('---');
          print(result);
          print('---');
        }
        return result;
      }
    }
    return null;
  }

  /// 构建房间的祖先路径集合（含自身）。
  /// 基于扁平 BuildingMap：通过 getParentRoom 反复向上追溯。
  void _fillAncestorPath(String roomId, Set<String> path) {
    if (path.contains(roomId)) return;
    path.add(roomId);
    final parent = BuildingMap.getParentRoom(roomId);
    if (parent != null) _fillAncestorPath(parent, path);
  }

  FocusTraversalPolicy get policy => scanner;

  /// 核心寻址机 (Context-Free 版)
  /// 负责解析图纸 members 并落地物理节点
  void _executeSearch(String targetId, {bool allowUnpack = true}) {
    if (intentionRoomId.value == null && !allowUnpack) return;

    // 优先：图纸拆解（按 getMembers 顺序迭代）
    if (allowUnpack && BuildingMap.isRoom(targetId)) {
      final members = BuildingMap.getMembers(targetId);

      for (final member in members) {
        if (member == '*') {
          final dynamicNodeInfo = _nodeRegistry.entries
              .where(
                (e) =>
                    e.value.roomId == targetId && e.value.node.canRequestFocus,
              )
              .firstOrNull;
          if (dynamicNodeInfo != null) {
            _applyLanding(
              dynamicNodeInfo.key,
              dynamicNodeInfo.value,
              targetId,
              '(via *)',
            );
            return;
          }
        } else {
          final staticNodeInfo = _nodeRegistry[member];
          if (staticNodeInfo != null && staticNodeInfo.node.canRequestFocus) {
            _applyLanding(member, staticNodeInfo, targetId, '');
            return;
          }
        }
      }
      return;
    }

    // 兜底：直接 ID 匹配
    final info = _nodeRegistry[targetId];
    if (info != null && info.node.canRequestFocus) {
      _applyLanding(targetId, info, targetId, '');
      return;
    }
  }

  void _applyLanding(
    String nodeId,
    _NodeInfo info,
    String targetId,
    String tag,
  ) {
    print('4，目标回应：[${info.roomId}] 准备就绪 (Atomic)');
    print('5，准备跳转：$_lastActionSource ——> [${info.roomId}:$nodeId] $tag');
    print('6，成功落地：[${info.roomId}:$nodeId]');

    final statusLog = onRoomEnter(info.roomId, printLog: false);
    if (statusLog != null) print(statusLog);
    print('---');

    intentionRoomId.value = null;
    info.node.requestFocus();
  }

  /// Back 导航：传送门弹栈 > 地图溯源
  ///
  /// 落点优先级：
  ///   A. 门节点（父房间中 id == currentRoomId 的入口按钮）
  ///   B. 父房间第一个可用成员
  void onBack(BuildContext context) {
    final String? room = currentRoomId;

    final String? focusedId = _nodeRegistry.entries
        .where((e) => e.value.node.hasFocus)
        .firstOrNull
        ?.key;
    final String currentPos = focusedId != null
        ? '[${_nodeRegistry[focusedId]?.roomId}：$focusedId]'
        : room != null
        ? '[$room]'
        : '未知';

    print('---');
    print('1，当前位置：$currentPos');

    String? targetId;
    String reason;

    // --- 优先级 1：传送门弹栈 ---
    if (_portalStack.isNotEmpty && _portalStack.last.landedIn == room) {
      final entry = _portalStack.removeLast();
      targetId = entry.returnTo;
      reason = '传送门弹栈：飞回 [$targetId]';

      // 直接用压栈时存储的 FocusNode 引用落地，绕开注册表
      final returnNode = entry.returnToFocusNode;
      if (returnNode != null && returnNode.canRequestFocus) {
        _lastActionSource = currentPos;
        print('2，意图回归：[$targetId] ($reason)');
        print('3，协议校验：Back 序列已启动');
        final statusLog = onRoomEnter(entry.returnTo, printLog: false);
        if (statusLog != null) print(statusLog);
        print('4，目标回应：[$targetId] 准备就绪 (Portal Return)');
        print('5，准备跳转：$currentPos ——> [$targetId] (传送门节点)');
        returnNode.requestFocus();
        print('6，成功落地：[$targetId]');
        print('---');
        return;
      }
    }
    // --- 优先级 2：地图溯源 ---
    else if (room != null) {
      if (BuildingMap.isRoot(room)) {
        reason = '已到达根房间边界 [$room]';
      } else {
        targetId = BuildingMap.getParentRoom(room);
        if (targetId != null) {
          reason = '地图溯源：[$room] → [$targetId]';
        } else {
          reason = '已到达逻辑边界';
        }
      }
    } else {
      reason = '当前房间未知';
    }

    if (targetId != null) {
      _lastActionSource = currentPos;
      print('2，意图回归：[$targetId] ($reason)');
      print('3，协议校验：Back 序列已启动');

      intentionRoomId.value = targetId;

      // --- 落点优先级 A：门节点 ---
      final doorNodeInfo = room != null ? _nodeRegistry[room] : null;
      if (doorNodeInfo != null &&
          doorNodeInfo.roomId == targetId &&
          doorNodeInfo.node.canRequestFocus) {
        _applyLanding(room!, doorNodeInfo, targetId, '(门节点)');
        return;
      }

      // --- 落点优先级 B：父房间第一个可用成员 ---
      _executeSearch(targetId, allowUnpack: true);
    } else {
      print('⚠️ 返回失败：$reason');
      print('---');
    }
  }

  /// 获取节点或房间的直接父房间 ID。
  /// 先查注册表（节点所属的 roomId），再查地图（房间的父房间）。
  String? getParentRoomId(String id) {
    final nodeInfo = _nodeRegistry[id];
    if (nodeInfo != null && nodeInfo.roomId != id) return nodeInfo.roomId;
    return BuildingMap.getParentRoom(id);
  }

  void onAction(BuildContext context, String id) {
    if (activeRoomNotifier.value == null) return;
    final String currentRoom = activeRoomNotifier.value!;
    _lastActionSource = '[$currentRoom:$id]';

    // --- 路径 1：虫洞传送（-> 前缀）→ 压栈，Back 时弹栈飞回 ---
    final String? portalTarget = BuildingMap.resolvePortalDestination(
      currentRoom,
      id,
    );
    if (portalTarget != null) {
      print('---');
      print('1，当前位置：[$currentRoom:$id]');
      print('2，意图房间：[Portal:$portalTarget]');
      _portalStack.add(
        _PortalEntry(
          landedIn: portalTarget,
          returnTo: currentRoom,
          returnToFocusNode: FocusManager.instance.primaryFocus,
        ),
      );
      print('3，传送门压栈：[$currentRoom] → [$portalTarget]，Esc 可取消');
      intentionRoomId.value = portalTarget;
      _executeSearch(portalTarget);
      return;
    }

    // --- 路径 2：普通推门（子房间 / Zone）→ 不压栈，Back 走地图溯源 ---
    final String? roomTarget = BuildingMap.resolveRoomEntry(currentRoom, id);
    if (roomTarget != null) {
      print('---');
      print('1，当前位置：[$currentRoom:$id]');
      print('2，意图房间：[Room:$roomTarget]');
      print('3，推门进入：[$currentRoom] → [$roomTarget]');
      intentionRoomId.value = roomTarget;
      _executeSearch(roomTarget);
      return;
    }

    // --- 路径 3：非授权的跨房间跳转 → 拦截 ---
    if (BuildingMap.isRoom(id)) {
      print('🚨 【架构拦截报告】 检测到非授权跨域跳转！[$currentRoom] → [$id]');
    }
  }

  /// Zone 判断：委托给 BuildingMap
  bool isZone(String id) => BuildingMap.isZone(id);
}

class _NodeInfo {
  final FocusNode node;
  final String roomId;
  _NodeInfo(this.node, this.roomId);
}

/// 传送门历史条目
class _PortalEntry {
  final String landedIn;
  final String returnTo;
  final FocusNode? returnToFocusNode;
  const _PortalEntry({
    required this.landedIn,
    required this.returnTo,
    this.returnToFocusNode,
  });
}
