import 'package:flutter/widgets.dart';
import 'interaction_controller.dart';
import 'interaction_state.dart';
import 'building_map.dart';
import '../../log/log_api.dart';

class MouseController extends BaseInteractionController {
  @override
  void init(InteractionState state) {
    super.init(state);
    // 补丁 1：强制将 cursorReportNotifier 清空，并且如果后续被外部试图修改也能被接管（静音）
    state.cursorReportNotifier.value = null;
    state.cursorReportNotifier.addListener(_muteVisualPipeline);
  }

  void _muteVisualPipeline() {
    if (state.cursorReportNotifier.value != null) {
      // 强制休眠游标渲染引擎
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.cursorReportNotifier.value = null;
      });
    }
  }

  @override
  void onMove(TraversalDirection direction) {
    // 鼠标模式下忽略遥控器专属的移动意图
  }

  @override
  void onConfirm() {
    // 鼠标模式下由点击直接触发事件，此遥控器专用的全局确认键可忽略
  }

  @override
  void onBack() {
    // 鼠标模式下支持 ESC/返回 退出 Overlay 页面（沿拓扑路径回退）
    final path = state.topologyNotifier.value.activePath;
    if (path.length > 1) {
      final currentRoom = state.topologyNotifier.value.activeRoom;
      if (currentRoom != null) {
        final parentRoom = BuildingMap.getParentRoom(currentRoom);
        if (parentRoom != null) {
          onRoomEnter(parentRoom);
          return;
        }
      }
      final pathList = path.toList();
      onRoomEnter(pathList[pathList.length - 2]);
    }
  }

  @override
  void onPointerEnter(String targetId) {
    // 悬停本身不需要触发全地图的焦距移动，仅用作可能的悬停态反馈，但游标已静音
  }

  @override
  void onPointerClick(String targetId) {
    // 处理鼠标点击事件，查字典找到对应房间并直接进入，绕过一切父子限制，实现空间瞬移
    final info = state.nodeRegistry[targetId];
    if (info != null) {
      Log.d(LogGroup.focus, '🖱️ 鼠标瞬间跃迁：点击目标 [$targetId] -> 所属房间 [${info.roomId}]');

      // 补丁 3：拓扑图的“空间瞬移”垃圾回收 (Topology GC)
      _topologyGC();

      // 直接进入该房间，刷新 UI 状态
      onRoomEnter(info.roomId);

      // 根据 BuildingMap 检查并执行可能的拓扑跳转 (例如 Overlay 的传送门)
      onAction(info.roomId, targetId);

      // 触发目标的动作 (例如 Navigator.push)
      info.onPressed?.call();
    }
  }

  @override
  void onNodeRegistered(String id) {
    // 鼠标模式不需要像焦点模式那样注册后尝试 fulfilled 遗留的意图，直接忽略
  }

  void _topologyGC() {
    // 强制清空 InteractionState.portalStack
    state.portalStack.clear();
    // 刷新 BuildingMap 的动态父级缓存
    BuildingMap.clearDynamicCache();
  }

  @override
  void onRoomEnter(String roomId) {
    if (state.currentRoomId != roomId) {
      final oldPath = state.topologyNotifier.value.activePath;
      final newPath = <String>{};
      _fillAncestorPath(roomId, newPath);

      state.topologyNotifier.value = FocusTopology(
        activeRoom: roomId,
        activePath: newPath,
      );

      final deactivated = oldPath.difference(newPath);
      final activated = newPath.difference(oldPath);

      if (deactivated.isNotEmpty || activated.isNotEmpty) {
        if (deactivated.isNotEmpty) {
          Log.d(LogGroup.focus, '状态熄灭：$deactivated');
        }
        if (activated.isNotEmpty) {
          Log.d(LogGroup.focus, '状态激活：$activated');
        }
      }
    }
  }

  void _fillAncestorPath(String roomId, Set<String> path) {
    if (path.contains(roomId)) return;
    path.add(roomId);
    final parent = BuildingMap.getParentRoom(roomId);
    if (parent != null) _fillAncestorPath(parent, path);
  }

  @override
  void onAction(String sourceRoom, String id, {bool asTerminalRoom = false}) {
    // 鼠标模式下的空间跳转：直接计算目标房间并跃迁，不产生任何等待状态和动画延迟
    final String? portalTarget = BuildingMap.resolvePortalDestination(sourceRoom, id);
    if (portalTarget != null) {
      Log.d(LogGroup.focus, '🖱️ 鼠标跃迁 (传送门)：[$sourceRoom:$id] -> [Portal:$portalTarget]');
      onRoomEnter(portalTarget);
      return;
    }

    final String? roomTarget = BuildingMap.resolveRoomEntry(sourceRoom, id);
    if (roomTarget != null) {
      Log.d(LogGroup.focus, '🖱️ 鼠标跃迁 (推门)：[$sourceRoom:$id] -> [Room:$roomTarget]');
      // 动态报备父子关系，以支持 StageView 正确计算嵌套层级
      BuildingMap.registerDynamicParent(roomTarget, sourceRoom, asTerminalRoom: asTerminalRoom);
      onRoomEnter(roomTarget);
      return;
    }

    final String? navTarget = BuildingMap.resolveNavTarget(sourceRoom, id);
    if (navTarget != null) {
      Log.d(LogGroup.focus, '🖱️ 鼠标跃迁 (导航)：[$sourceRoom:$id] -> [Nav:$navTarget]');
      onRoomEnter(navTarget);
      return;
    }

    if (BuildingMap.isRoom(id, inRoomId: sourceRoom)) {
      Log.d(LogGroup.focus, '🚨 鼠标拦截：非授权跨域跳转！[$sourceRoom] -> [$id]');
    }
  }
}
