import 'package:flutter/material.dart';
import 'package:superfocus/core/stage/stage_manager.dart';
import '../control/superfocus/focus_api.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_manager.dart';
import 'stage_models.dart';
import 'stage_registry.dart';
import 'stage_physical_frame.dart';
import '../log/log_api.dart';
import 'stage_room_transition.dart';
import 'stage_contract.dart';

/// 商管总调度台 (The Stage Manager Brain)
/// 职责：打破“先有鸡还是先有蛋”的悖论，监听意图并提前施工。
class StageView extends StatefulWidget {
  final Widget sidebar;

  const StageView({super.key, required this.sidebar});

  @override
  State<StageView> createState() => _StageViewState();
}

class _StageViewState extends State<StageView> {
  /// 幕后休息室 (缓存)
  final Map<String, Widget> _suspendedRooms = {};

  /// 正在播放退出动画的房间集合
  final Set<String> _roomsExiting = {};

  @override
  Widget build(BuildContext context) {
    // ✅ 关键修复：同时监听 拓扑变化 和 导航意图
    return ListenableBuilder(
      listenable: Listenable.merge([
        SuperFocusManager.instance.topologyNotifier,
        SuperFocusManager.instance.intentionRoomId,
      ]),
      builder: (context, _) {
        final topology = SuperFocusManager.instance.topologyNotifier.value;
        final intentionId = SuperFocusManager.instance.intentionRoomId.value;

        Log.d(
          LogGroup.ui,
          '🎭 收到信号! 激活点: ${topology.activeRoom}, 意图点: $intentionId',
          subGroup: 'StageBrain',
        );

        // 副作用排队
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _syncRooms(topology, intentionId),
        );

        return _buildPhysicalFrame(topology, intentionId);
      },
    );
  }

  void _syncRooms(FocusTopology topology, String? intentionId) {
    if (!mounted) return;

    final logicalPath = topology.logicalPath;
    bool needsUpdate = false;

    // 1. 检查哪些房间需要入场：在完整逻辑路径上的，或者是当前正准备进入的意图房间
    final Set<String> neededRoomIds = Set.from(logicalPath);
    if (intentionId != null) neededRoomIds.add(intentionId);

    bool hasSecondFloor = false;

    for (final roomId in neededRoomIds) {
      final contract = StageRegistry.getContract(roomId);
      if (contract != null) {
        if (contract.zone == StageZone.secondFloorScreen) {
          hasSecondFloor = true;
        }
        if (!_suspendedRooms.containsKey(roomId)) {
          Log.d(
            LogGroup.ui,
            '🚀 路径激活! 提前为 [$roomId] 施工...',
            subGroup: 'StageBrain',
          );
          _suspendedRooms[roomId] = contract.builder != null
              ? contract.builder!(context)
              : contract.dynamicBuilder!(context, roomId);
          needsUpdate = true;
        }
      }
    }

    // 动态同步侧边栏窄框模式状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (StageManager.instance.isSecondFloorActive.value != hasSecondFloor) {
        StageManager.instance.isSecondFloorActive.value = hasSecondFloor;
      }
    });

    // 2. 检查哪些房间可以撤场（不再在逻辑路径中）
    _suspendedRooms.forEach((roomId, _) {
      final contract = StageRegistry.getContract(roomId);
      if (contract != null &&
          !logicalPath.contains(roomId) &&
          roomId != intentionId &&
          !contract.keepAlive) {
        if (!_roomsExiting.contains(roomId)) {
          _roomsExiting.add(roomId);
          Log.d(LogGroup.ui, '🧹 开启延时撤场 [$roomId]...', subGroup: 'StageBrain');

          Future.delayed(contract.exitDelay, () {
            if (mounted) {
              final currentTopology =
                  SuperFocusManager.instance.topologyNotifier.value;
              final currentIntention =
                  SuperFocusManager.instance.intentionRoomId.value;
              final stillNotNeeded =
                  !currentTopology.logicalPath.contains(roomId) &&
                  currentIntention != roomId;
              setState(() {
                _roomsExiting.remove(roomId);
                if (stillNotNeeded) {
                  _suspendedRooms.remove(roomId);
                }
              });
            }
          });
        }
      }
    });

    if (needsUpdate) {
      setState(() {});
    }
  }

  Widget _buildPhysicalFrame(FocusTopology topology, String? intentionId) {
    final List<Widget> firstFloorSlots = [];
    final List<Widget> secondFloorSlots = [];
    final List<Widget> thirdFloorSlots = [];

    _suspendedRooms.forEach((roomId, roomWidget) {
      final contract = StageRegistry.getContract(roomId);
      if (contract == null) return;

      // 可见性：只要在逻辑路径中，就在物理上可见（但可能被上层遮挡）
      final bool isVisible =
          topology.logicalPath.contains(roomId) || intentionId == roomId;
      // 活跃性：只有在当前真正的激活树上，或者正在播放退场动画时，才允许交互和动画刷新
      final bool isExiting = _roomsExiting.contains(roomId);
      final bool isActive =
          topology.activePath.contains(roomId) ||
          intentionId == roomId ||
          isExiting;

      final wrappedWidget = _wrapRoom(
        child: roomWidget,
        isVisible: isVisible,
        isActive: isActive,
        contract: contract,
        heroRect: topology.heroRect,
      );

      if (contract.zone == StageZone.thirdFloorOverlay) {
        thirdFloorSlots.add(wrappedWidget);
      } else if (contract.zone == StageZone.secondFloorScreen) {
        secondFloorSlots.add(wrappedWidget);
      } else if (contract.zone == StageZone.firstFloorMain) {
        firstFloorSlots.add(wrappedWidget);
      }
    });

    return StagePhysicalFrame(
      firstFloorContent: firstFloorSlots,
      secondFloorContent: secondFloorSlots,
      sidebar: widget.sidebar,
      thirdFloorContent: thirdFloorSlots,
    );
  }

  Widget _wrapRoom({
    required Widget child,
    required bool isVisible,
    required bool isActive,
    required StageContract contract,
    required Rect? heroRect,
  }) {
    Widget wrapped = child;

    // 保持 Widget 树结构不变，通过参数控制状态，防止 Element 被销毁导致焦点丢失
    wrapped = IgnorePointer(
      ignoring: !isActive,
      child: TickerMode(
        enabled: isActive,
        child: wrapped,
      ),
    );

    if (contract.customTransition != null) {
      return contract.customTransition!(context, wrapped, isVisible, heroRect);
    }

    if (contract.zone == StageZone.firstFloorMain || contract.zone == StageZone.secondFloorScreen) {
      return StageRoomTransition(isVisible: isVisible, child: wrapped);
    }

    return Offstage(offstage: !isVisible, child: wrapped);
  }
}
