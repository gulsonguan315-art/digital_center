import 'package:flutter/material.dart';
import '../control/superfocus/focus_api.dart';
import '../control/superfocus/interaction_manager.dart';
import 'stage_models.dart';
import 'stage_registry.dart';
import 'stage_physical_frame.dart';
import '../log/log_api.dart';
import 'stage_room_transition.dart';

/// 商管总调度台 (The Stage Manager Brain)
/// 职责：打破“先有鸡还是先有蛋”的悖论，监听意图并提前施工。
class StageView extends StatefulWidget {
  const StageView({super.key});

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
        
        Log.d(LogGroup.ui, '🎭 收到信号! 激活点: ${topology.activeRoom}, 意图点: $intentionId', subGroup: 'StageBrain');
        
        // 副作用排队
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncRooms(topology, intentionId));

        return _buildPhysicalFrame(topology, intentionId);
      },
    );
  }

  void _syncRooms(FocusTopology topology, String? intentionId) {
    if (!mounted) return;
    
    final activePath = topology.activePath;
    bool needsUpdate = false;

    // 检查哪些房间需要入场：在激活路径上的，或者是当前正准备进入的意图房间
    for (final contract in StageRegistry.allContracts) {
      final bool isNeeded = activePath.contains(contract.roomId) || 
                          contract.roomId == intentionId;

      if (isNeeded) {
        if (!_suspendedRooms.containsKey(contract.roomId)) {
          Log.d(LogGroup.ui, '🚀 意图检测/路径激活! 提前为 [${contract.roomId}] 施工...', subGroup: 'StageBrain');
          _suspendedRooms[contract.roomId] = contract.builder(context);
          needsUpdate = true;
        }
      }
    }

    // 检查哪些房间可以撤场，并开启 350ms 的延时撤场以播放退出动画
    _suspendedRooms.forEach((roomId, _) {
      final contract = StageRegistry.getContract(roomId);
      if (contract != null && 
          !activePath.contains(roomId) && 
          roomId != intentionId && 
          !contract.keepAlive) {
        if (!_roomsExiting.contains(roomId)) {
          _roomsExiting.add(roomId);
          Log.d(LogGroup.ui, '🧹 开启 350ms 延时撤场 [$roomId]...', subGroup: 'StageBrain');
          
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) {
              final currentTopology = SuperFocusManager.instance.topologyNotifier.value;
              final currentIntention = SuperFocusManager.instance.intentionRoomId.value;
              final stillNotNeeded = !currentTopology.activePath.contains(roomId) && 
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
    final List<Widget> mainSlots = [];
    final List<Widget> overlaySlots = [];

    _suspendedRooms.forEach((roomId, roomWidget) {
      final contract = StageRegistry.getContract(roomId);
      if (contract == null) return;

      // 显隐逻辑：只要该房间在当前的激活路径上，或者是正要进入的目标，就必须可见
      final bool isVisible = topology.activePath.contains(roomId) || intentionId == roomId;
      final bool isMainStage = contract.zone == StageZone.main;
      final wrappedWidget = _wrapRoom(roomWidget, isVisible, isMainStage);

      if (isMainStage) {
        mainSlots.add(wrappedWidget);
      } else {
        overlaySlots.add(wrappedWidget);
      }
    });

    return StagePhysicalFrame(
      mainStageContent: mainSlots,
      overlayStageContent: overlaySlots,
    );
  }

  Widget _wrapRoom(Widget child, bool isFocused, bool isMainStage) {
    if (isMainStage) {
      return StageRoomTransition(
        isVisible: isFocused,
        child: child,
      );
    }
    return Offstage(
      offstage: !isFocused,
      child: TickerMode(
        enabled: isFocused,
        child: child,
      ),
    );
  }
}
