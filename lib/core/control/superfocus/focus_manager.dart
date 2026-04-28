import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'scoped_2d_scanner.dart';
import 'building_map.dart';

/// 当前焦点拓扑状态快照
class FocusTopology {
  final String? activeRoom;
  final Set<String> activePath;

  const FocusTopology({this.activeRoom, this.activePath = const {}});
}

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

  final ValueNotifier<FocusTopology> topologyNotifier = ValueNotifier(
    const FocusTopology(),
  );

  String? get currentRoomId => topologyNotifier.value.activeRoom;

  final Scoped2dScanner scanner = const Scoped2dScanner();
  final Map<String, _NodeInfo> _nodeRegistry = {};
  final ValueNotifier<String?> intentionRoomId = ValueNotifier(null);
  String? _lastActionSource;
  bool _pendingCallback = false;
  final List<_PortalEntry> _portalStack = [];

  void cancelNavigation() {
    if (intentionRoomId.value != null) {
      logCancel(intentionRoomId.value);
      intentionRoomId.value = null;
      if (_portalStack.isNotEmpty) _portalStack.removeLast();
    }
  }

  void registerNode(String id, FocusNode node, String roomId) {
    _nodeRegistry[id] = _NodeInfo(node, roomId);

    _tryFulfillIntention();
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

  void unregisterNode(String id) {
    _nodeRegistry.remove(id);
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

  void onRoomEnter(String roomId, {bool printLog = true}) {
    if (currentRoomId != roomId) {
      final oldPath = topologyNotifier.value.activePath;
      final newPath = <String>{};
      _fillAncestorPath(roomId, newPath);

      topologyNotifier.value = FocusTopology(
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

  FocusTraversalPolicy get policy => scanner;

  void _executeSearch(String targetId, {bool allowUnpack = true}) {
    if (intentionRoomId.value == null && !allowUnpack) return;
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
    final String? focusedId = _nodeRegistry.entries
        .where((e) => e.value.node.hasFocus)
        .firstOrNull
        ?.key;

    final String? room = focusedId != null
        ? _nodeRegistry[focusedId]?.roomId
        : currentRoomId;

    final String currentPos = switch ((focusedId, room)) {
      (String f, String r) => '[$r：$f]',
      (null, String r) => '[$r]',
      _ => '未知',
    };

    logBackStart(currentPos);

    String? targetId;
    String reason;

    if (_portalStack.isNotEmpty && _portalStack.last.landedIn == room) {
      final entry = _portalStack.removeLast();
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

      final doorNodeInfo = room != null ? _nodeRegistry[room] : null;
      if (doorNodeInfo != null &&
          doorNodeInfo.roomId == targetId &&
          doorNodeInfo.node.canRequestFocus) {
        _applyLanding(room!, doorNodeInfo, targetId, '(门节点)');
        return;
      }

      _executeSearch(targetId, allowUnpack: true);
    } else {
      logBackFail(reason);
    }
  }

  String? getParentRoomId(String id) {
    final nodeInfo = _nodeRegistry[id];
    if (nodeInfo != null && nodeInfo.roomId != id) return nodeInfo.roomId;
    return BuildingMap.getParentRoom(id);
  }

  void onAction(String sourceRoom, String id) {
    _lastActionSource = '[$sourceRoom:$id]';
    final String? portalTarget = BuildingMap.resolvePortalDestination(
      sourceRoom,
      id,
    );
    if (portalTarget != null) {
      logPortalAction(sourceRoom, id, portalTarget);
      _portalStack.add(
        _PortalEntry(
          landedIn: portalTarget,
          returnTo: sourceRoom,
          returnToFocusNode: FocusManager.instance.primaryFocus,
        ),
      );
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

    if (BuildingMap.isRoom(id)) {
      logUnauthorizedAction(sourceRoom, id);
    }
  }

  bool isZone(String id) => BuildingMap.isZone(id);
}

class _NodeInfo {
  final FocusNode node;
  final String roomId;
  _NodeInfo(this.node, this.roomId);
}

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
