import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'scoped_2d_scanner.dart';
import 'building_map.dart';
import 'focus_report.dart';
import 'focus_state.dart';

mixin FocusTraceLogger {
  void logCancel(String? target) {
    assert(() {
      print('⏹️ 导航意图已取消：[$target]');
      return true;
    }());
  }

  void logStatusFire(String? deactivated, String? activated) {
    assert(() {
      if (deactivated != null && deactivated.isNotEmpty)
        print('状态熄灭：$deactivated');
      if (activated != null && activated.isNotEmpty) print('状态激活：$activated');
      return true;
    }());
  }

  void logLanding(String? source, String roomId, String nodeId, String tag) {
    assert(() {
      print('4，目标回应：[$roomId] 准备就绪 (Atomic)');
      print('5，准备跳转：${source ?? "系统"} ——> [$roomId:$nodeId] $tag');
      print('6，成功落地：[$roomId:$nodeId]');
      return true;
    }());
  }

  void logBackStart(String currentPos) {
    assert(() {
      print('---\n1，当前位置：$currentPos');
      return true;
    }());
  }

  void logBackIntent(String targetId, String reason) {
    assert(() {
      print('2，意图回归：[$targetId] ($reason)');
      print('3，协议校验：Back 序列已启动');
      return true;
    }());
  }

  void logPortalReturn(String targetId, String currentPos) {
    assert(() {
      print('4，目标回应：[$targetId] 准备就绪 (Portal Return)');
      print('5，准备跳转：$currentPos ——> [$targetId] (传送门节点)');
      print('6，成功落地：[$targetId]\n---');
      return true;
    }());
  }

  void logBackFail(String reason) {
    assert(() {
      print('⚠️ 返回失败：$reason\n---');
      return true;
    }());
  }

  void logPortalAction(String currentRoom, String id, String portalTarget) {
    assert(() {
      print('---\n1，当前位置：[$currentRoom:$id]');
      print('2，意图房间：[Portal:$portalTarget]');
      print('3，传送门压栈：[$currentRoom] → [$portalTarget]，Esc 可取消');
      return true;
    }());
  }

  void logRoomAction(String currentRoom, String id, String roomTarget) {
    assert(() {
      print('---\n1，当前位置：[$currentRoom:$id]');
      print('2，意图房间：[Room:$roomTarget]');
      print('3，推门进入：[$currentRoom] → [$roomTarget]');
      return true;
    }());
  }

  void logUnauthorizedAction(String currentRoom, String id) {
    assert(() {
      print('🚨 【架构拦截报告】 检测到非授权跨域跳转！[$currentRoom] → [$id]');
      return true;
    }());
  }
}

class SuperFocusManager with FocusTraceLogger {
  static final SuperFocusManager instance = SuperFocusManager._internal();
  SuperFocusManager._internal();

  /// 焦点系统的 RAM (内存单元)
  final FocusState state = FocusState();

  // --- 兼容性代理 (指向 RAM 中的寄存器) ---
  ValueNotifier<FocusTopology> get topologyNotifier => state.topologyNotifier;
  ValueNotifier<FocusReport?> get cursorReportNotifier => state.cursorReportNotifier;
  ValueNotifier<bool> get cursorHiddenNotifier => state.cursorHiddenNotifier;
  String? get currentRoomId => state.currentRoomId;

  // --- CPU 内部临时状态 ---
  final ValueNotifier<String?> intentionRoomId = ValueNotifier(null);
  String? _lastActionSource;
  bool _pendingCallback = false;

  final Scoped2dScanner scanner = const Scoped2dScanner();
  FocusTraversalPolicy get policy => scanner;

  // --- RAM 操作指令 ---

  void reportCursor(FocusReport report) {
    if (state.cursorReportNotifier.value == report) return;
    state.cursorReportNotifier.value = report;
  }

  void hideCursor() => state.cursorHiddenNotifier.value = true;
  void showCursor() => state.cursorHiddenNotifier.value = false;
  void clearCursor() => state.cursorReportNotifier.value = null;

  void registerNode(String id, FocusNode node, String roomId) {
    state.nodeRegistry[id] = FocusNodeInfo(node, roomId);
    _tryFulfillIntention();
  }

  void unregisterNode(String id) => state.nodeRegistry.remove(id);

  void cancelNavigation() {
    if (intentionRoomId.value != null) {
      logCancel(intentionRoomId.value);
      intentionRoomId.value = null;
      if (state.portalStack.isNotEmpty) state.portalStack.removeLast();
    }
  }

  void _tryFulfillIntention() {
    final target = intentionRoomId.value;
    if (target == null) return;
    if (_pendingCallback) return;
    _pendingCallback = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingCallback = false;
      if (intentionRoomId.value == target) {
        _executeSearch(target);
      }
    });
  }

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

  // --- CPU 逻辑指令 (计算与跳转) ---

  void onRoomEnter(String roomId, {bool printLog = true}) {
    if (currentRoomId != roomId) {
      final oldPath = state.topologyNotifier.value.activePath;
      final newPath = <String>{};
      _fillAncestorPath(roomId, newPath);

      state.topologyNotifier.value = FocusTopology(
        activeRoom: roomId,
        activePath: newPath,
      );

      final deactivated = oldPath.difference(newPath);
      final activated = newPath.difference(oldPath);

      if (printLog && (deactivated.isNotEmpty || activated.isNotEmpty)) {
        assert(() {
          print('---');
          return true;
        }());
        logStatusFire(
          deactivated.isNotEmpty ? deactivated.toString() : null,
          activated.isNotEmpty ? activated.toString() : null,
        );
        assert(() {
          print('---');
          return true;
        }());
      }
    }
  }

  void _fillAncestorPath(String roomId, Set<String> path) {
    if (path.contains(roomId)) return;
    path.add(roomId);
    final parent = BuildingMap.getParentRoom(roomId);
    if (parent != null) _fillAncestorPath(parent, path);
  }

  void _executeSearch(String targetId, {bool allowUnpack = true}) {
    if (intentionRoomId.value == null && !allowUnpack) return;
    if (allowUnpack && BuildingMap.isRoom(targetId)) {
      final members = BuildingMap.getMembers(targetId);
      for (final member in members) {
        if (member == '*') {
          final dynamicNodeInfo = state.nodeRegistry.entries
              .where((e) => e.value.roomId == targetId && e.value.node.canRequestFocus)
              .firstOrNull;
          if (dynamicNodeInfo != null) {
            _applyLanding(dynamicNodeInfo.key, dynamicNodeInfo.value, targetId, '(via *)');
            return;
          }
        } else {
          final staticNodeInfo = state.nodeRegistry[member];
          if (staticNodeInfo != null && staticNodeInfo.node.canRequestFocus) {
            _applyLanding(member, staticNodeInfo, targetId, '');
            return;
          }
        }
      }
      return;
    }

    final info = state.nodeRegistry[targetId];
    if (info != null && info.node.canRequestFocus) {
      _applyLanding(targetId, info, targetId, '');
      return;
    }
  }

  void _applyLanding(String nodeId, FocusNodeInfo info, String targetId, String tag) {
    logLanding(_lastActionSource, info.roomId, nodeId, tag);
    onRoomEnter(info.roomId, printLog: false);
    assert(() {
      print('---');
      return true;
    }());
    intentionRoomId.value = null;
    info.node.requestFocus();
  }

  void onBack(BuildContext context) {
    final String? focusedId = state.nodeRegistry.entries
        .where((e) => e.value.node.hasPrimaryFocus)
        .firstOrNull
        ?.key;

    final String? room = focusedId != null ? state.nodeRegistry[focusedId]?.roomId : currentRoomId;
    final String currentPos = switch ((focusedId, room)) {
      (String f, String r) => '[$r：$f]',
      (null, String r) => '[$r]',
      _ => '未知',
    };

    logBackStart(currentPos);
    String? targetId;
    String reason;

    if (state.portalStack.isNotEmpty && state.portalStack.last.landedIn == room) {
      final entry = state.portalStack.removeLast();
      targetId = entry.returnTo;
      reason = '传送门弹栈：飞回 [$targetId]';
      final returnNode = entry.returnToFocusNode;
      if (returnNode != null && returnNode.canRequestFocus) {
        _lastActionSource = currentPos;
        logBackIntent(targetId, reason);
        onRoomEnter(entry.returnTo, printLog: false);
        logPortalReturn(targetId, currentPos);
        returnNode.requestFocus();
        return;
      }
    } else if (room != null) {
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
      logBackIntent(targetId, reason);
      intentionRoomId.value = targetId;

      final entryNodeId = room != null ? BuildingMap.getEntryNodeForRoom(targetId, room) : null;
      final entryNodeInfo = entryNodeId != null ? state.nodeRegistry[entryNodeId] : null;
      if (entryNodeId != null && entryNodeInfo != null && entryNodeInfo.roomId == targetId && entryNodeInfo.node.canRequestFocus) {
        _applyLanding(entryNodeId, entryNodeInfo, targetId, '(nav entry)');
        return;
      }

      final doorNodeInfo = room != null ? state.nodeRegistry[room] : null;
      if (doorNodeInfo != null && doorNodeInfo.roomId == targetId && doorNodeInfo.node.canRequestFocus) {
        _applyLanding(room!, doorNodeInfo, targetId, '(门节点)');
        return;
      }

      _executeSearch(targetId, allowUnpack: true);
    } else {
      logBackFail(reason);
    }
  }

  void onAction(String sourceRoom, String id) {
    _lastActionSource = '[$sourceRoom:$id]';
    final String? portalTarget = BuildingMap.resolvePortalDestination(sourceRoom, id);
    if (portalTarget != null) {
      logPortalAction(sourceRoom, id, portalTarget);
      state.portalStack.add(PortalEntry(
        landedIn: portalTarget,
        returnTo: sourceRoom,
        returnToFocusNode: FocusManager.instance.primaryFocus,
      ));
      intentionRoomId.value = portalTarget;
      _executeSearch(portalTarget);
      return;
    }

    final String? roomTarget = BuildingMap.resolveRoomEntry(sourceRoom, id);
    if (roomTarget != null) {
      logRoomAction(sourceRoom, id, roomTarget);
      intentionRoomId.value = roomTarget;
      _executeSearch(roomTarget);
      return;
    }

    final String? navTarget = BuildingMap.resolveNavTarget(sourceRoom, id);
    if (navTarget != null) {
      logRoomAction(sourceRoom, id, navTarget);
      intentionRoomId.value = navTarget;
      _executeSearch(navTarget);
      return;
    }

    if (BuildingMap.isRoom(id)) {
      logUnauthorizedAction(sourceRoom, id);
    }
  }

  bool isZone(String id) => BuildingMap.isZone(id);
}
