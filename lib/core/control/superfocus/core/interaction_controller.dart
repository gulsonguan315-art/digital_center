import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_state.dart';
import '../../../log/log_api.dart';

/// 交互控制器基类
/// 定义了外部系统（如按键、UI 组件）可以触发的标准动作。
abstract class BaseInteractionController {
  late final InteractionState state;
  final ValueNotifier<String?> intentionRoomId = ValueNotifier(null);
  Timer? _intentionTimeoutTimer;

  /// 初始化控制器
  void init(InteractionState state) {
    this.state = state;
    intentionRoomId.addListener(() {
      _intentionTimeoutTimer?.cancel();
      final target = intentionRoomId.value;
      if (target != null) {
        _intentionTimeoutTimer = Timer(const Duration(milliseconds: 1000), () {
          if (intentionRoomId.value == target) {
            Log.d(LogGroup.focus, '⏰ 焦点系统：导航意图超时，启动自动解锁保护释放意图：[$target]');
            intentionRoomId.value = null;
          }
        });
      }
    });
  }

  /// 【移动意图】处理方向键移动（遥控器专属）
  void onMove(TraversalDirection direction);

  /// 【确认意图】处理确认按键
  void onConfirm();

  /// 【返回意图】处理返回/取消意图
  void onBack();

  /// 【主页意图】直接重置应用到初始状态
  void onHome();

  /// 【指针悬停】处理鼠标悬停事件（鼠标专属）
  void onPointerEnter(String targetId);

  /// 【指针点击】处理鼠标点击事件（鼠标专属）
  void onPointerClick(String targetId);

  /// 【节点注册】当新节点注册时触发，处理未完成的意图
  void onNodeRegistered(String id);

  /// 【房间进入】处理焦点/鼠标进入房间的逻辑，更新拓扑
  void onRoomEnter(String roomId);

  /// 【全局动作分发】处理具体的点击导航、传送门跳转逻辑
  void onAction(String sourceRoom, String id, {bool asTerminalRoom = false});
}
