import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'interaction_controller.dart';
import 'interaction_state.dart';
import 'scoped_2d_scanner.dart';
import 'building_map.dart';
import '../../log/log_api.dart';

mixin FocusTraceLogger {
  void logCancel(String? target) {
    Log.d(LogGroup.focus, '⏹️ 导航意图已取消：[$target]');
  }

  void logStatusFire(String? deactivated, String? activated) {
    if (deactivated != null && deactivated.isNotEmpty) {
      Log.d(LogGroup.focus, '状态熄灭：$deactivated');
    }
    if (activated != null && activated.isNotEmpty) {
      Log.d(LogGroup.focus, '状态激活：$activated');
    }
  }

  void logLanding(String? source, String roomId, String nodeId, String tag) {
    Log.d(
      LogGroup.focus,
      '\n4，目标回应：[$roomId] 准备就绪 (Atomic)\n5，准备跳转：${source ?? "系统"} ——> [$roomId:$nodeId] $tag\n6，成功落地：[$roomId:$nodeId]\n---',
    );
  }

  void logBackStart(String currentPos) {
    Log.d(LogGroup.focus, '---\n1，当前位置：$currentPos');
  }

  void logBackIntent(String targetId, String reason) {
    Log.d(LogGroup.focus, '2，意图回归：[$targetId] ($reason)\n3，协议校验：Back 序列已启动');
  }

  void logPortalReturn(String targetId, String currentPos) {
    Log.d(
      LogGroup.focus,
      '\n4，目标回应：[$targetId] 准备就绪 (Portal Return)\n5，准备跳转：$currentPos ——> [$targetId] (传送门节点)\n6，成功落地：[$targetId]\n---',
    );
  }

  void logBackFail(String reason) {
    Log.d(LogGroup.focus, '⚠️ 返回失败：$reason\n---');
  }

  void logPortalAction(String currentRoom, String id, String portalTarget) {
    Log.d(
      LogGroup.focus,
      '---\n1，当前位置：[$currentRoom:$id]\n2，意图房间：[Portal:$portalTarget]\n3，传送门压栈：[$currentRoom] → [$portalTarget]，Esc 可取消',
    );
  }

  void logRoomAction(String currentRoom, String id, String roomTarget) {
    Log.d(
      LogGroup.focus,
      '---\n1，当前位置：[$currentRoom:$id]\n2，意图房间：[Room:$roomTarget]\n3，推门进入：[$currentRoom] → [$roomTarget]',
    );
  }

  void logUnauthorizedAction(String currentRoom, String id) {
    Log.d(LogGroup.focus, '🚨 【架构拦截报告】 检测到非授权跨域跳转！[$currentRoom] → [$id]');
  }
}

class FocusController extends BaseInteractionController with FocusTraceLogger {
  // --- 兼容性代理 (指向 RAM 中的寄存器) ---
  String? get currentRoomId => state.currentRoomId;

  // --- CPU 内部临时状态 ---
  String? _lastActionSource;
  bool _pendingCallback = false;

  final Scoped2dScanner scanner = const Scoped2dScanner();
  FocusTraversalPolicy get policy => scanner;

  bool _actionDispatched = false;

  void cancelNavigation() {
    if (intentionRoomId.value != null) {
      logCancel(intentionRoomId.value);
      intentionRoomId.value = null;
      if (state.portalStack.isNotEmpty) state.portalStack.removeLast();
    }
  }

  @override
  void onNodeRegistered(String id) {
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

  @override
  void onMove(TraversalDirection direction) {
    if (intentionRoomId.value != null) return;
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return;
    policy.inDirection(primaryFocus, direction);
  }

  @override
  void onConfirm() {
    if (intentionRoomId.value != null) return;
    final entry = state.nodeRegistry.entries
        .where((e) => e.value.node.hasPrimaryFocus)
        .firstOrNull;
    if (entry == null) return;

    final info = entry.value;
    final id = entry.key;

    // 触发业务回调前重置标志
    _actionDispatched = false;
    info.onPressed?.call();

    // 如果业务层在 onPressed 中已经手动发起了导航（例如明确传递了 asTerminalRoom 等参数），
    // 则跳过引擎的默认自动导航，防止动作被执行两遍。
    if (_actionDispatched) return;

    // 触发默认的焦点导航动作
    final String sourceRoom = info.roomId.isNotEmpty
        ? info.roomId
        : (currentRoomId ?? '未知');
    if (sourceRoom != '未知') {
      onAction(sourceRoom, id);
    }
  }

  @override
  void onBack() {
    if (intentionRoomId.value != null) {
      cancelNavigation();
      return;
    }
    final String? focusedId = state.nodeRegistry.entries
        .where((e) => e.value.node.hasPrimaryFocus)
        .firstOrNull
        ?.key;

    final String? room = focusedId != null
        ? state.nodeRegistry[focusedId]?.roomId
        : currentRoomId;
    final String currentPos = switch ((focusedId, room)) {
      (String f, String r) => '[$r：$f]',
      (null, String r) => '[$r]',
      _ => '未知',
    };

    logBackStart(currentPos);
    String? targetId;
    String reason;

    if (state.portalStack.isNotEmpty &&
        state.portalStack.last.landedIn == room) {
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

      final entryNodeId = room != null
          ? BuildingMap.getEntryNodeForRoom(targetId, room)
          : null;
      final entryNodeInfo = entryNodeId != null
          ? state.nodeRegistry[entryNodeId]
          : null;
      if (entryNodeId != null &&
          entryNodeInfo != null &&
          entryNodeInfo.roomId == targetId &&
          entryNodeInfo.node.canRequestFocus) {
        _applyLanding(entryNodeId, entryNodeInfo, targetId, '(nav entry)');
        return;
      }

      final doorNodeInfo = room != null ? state.nodeRegistry[room] : null;
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
        logStatusFire(
          deactivated.isNotEmpty ? deactivated.toString() : null,
          activated.isNotEmpty ? activated.toString() : null,
        );
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

  void _applyLanding(
    String nodeId,
    FocusNodeInfo info,
    String targetId,
    String tag,
  ) {
    logLanding(_lastActionSource, info.roomId, nodeId, tag);
    onRoomEnter(info.roomId, printLog: false);
    intentionRoomId.value = null;
    info.node.requestFocus();
  }

  void onAction(String sourceRoom, String id, {bool asTerminalRoom = false}) {
    _actionDispatched = true;
    _lastActionSource = '[$sourceRoom:$id]';
    final String? portalTarget = BuildingMap.resolvePortalDestination(
      sourceRoom,
      id,
    );
    if (portalTarget != null) {
      logPortalAction(sourceRoom, id, portalTarget);
      state.portalStack.add(
        PortalEntry(
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

      // ✅ 关键：动态报备父子关系，确保 Back 逻辑能通过 _parentCache 飞回来
      // 传入 asTerminalRoom 标识，防止死胡同房间无限继承动态通配符
      BuildingMap.registerDynamicParent(
        roomTarget,
        sourceRoom,
        asTerminalRoom: asTerminalRoom,
      );

      // ✅ 关键：立即更新拓扑状态，让 UI 渲染出子房间内容
      onRoomEnter(roomTarget, printLog: false);

      intentionRoomId.value = roomTarget;
      _executeSearch(roomTarget);
      return;
    }

    final String? navTarget = BuildingMap.resolveNavTarget(sourceRoom, id);
    if (navTarget != null) {
      logRoomAction(sourceRoom, id, navTarget);
      onRoomEnter(navTarget, printLog: false);
      intentionRoomId.value = navTarget;
      _executeSearch(navTarget);
      return;
    }

    if (BuildingMap.isRoom(id, inRoomId: sourceRoom)) {
      logUnauthorizedAction(sourceRoom, id);
    }
  }

  // FocusController 专属的事件：忽略鼠标事件
  @override
  void onPointerEnter(String targetId) {}

  @override
  void onPointerClick(String targetId) {}
}
