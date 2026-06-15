library focus_api;

import 'package:flutter/material.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_manager.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import 'package:superfocus/core/control/superfocus/navigation/focus_report.dart';

// 1. 【暴露组件】
export 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart'
    show
        SuperFocusRoom,
        FocusIdentity,
        FocusCluster,
        FocusShape,
        FocusTopologyScope,
        FocusActionButton,
        MouseDismissRegion;

// 2. 【暴露模型】
export 'package:superfocus/core/control/superfocus/core/interaction_state.dart' show FocusTopology;
export 'package:superfocus/core/control/superfocus/navigation/focus_report.dart' show FocusTransitionMode;
export 'package:superfocus/core/control/superfocus/scroll/focus_alignment.dart' show FocusAlignment;
export 'package:superfocus/core/control/superfocus/navigation/focus_geometry.dart'
    show FocusGeometry, RoundedRectFocusGeometry, SidebarTileFocusGeometry;

/// 3. 【暴露命令】UI 发号施令的唯一遥控器
abstract class FocusAPI {
  /// 发送焦点动作意图
  /// [asTerminalRoom] - 如果进入的是一个死胡同/预览房间，设置为 true 可阻断动态子房间继承
  static void dispatchAction(
    String currentRoom,
    String id, {
    bool asTerminalRoom = false,
  }) {
    SuperFocusManager.instance.onAction(
      currentRoom,
      id,
      asTerminalRoom: asTerminalRoom,
    );
  }

  /// 声明下一次焦点跳转所使用的过渡动画模式
  static void requestNextTransition(FocusTransitionMode mode, {Duration? delay}) {
    SuperFocusManager.instance.requestNextTransition(mode, delay: delay);
  }

  /// 当前是否处于网络数据加载期（虚线转圈状态），可用于拦截输入
  static bool get isCursorWaiting =>
      SuperFocusManager.instance.cursorWaitingNotifier.value;

  /// 当前是否处于全局游标隐身转场期（Teleport等），可用于拦截输入
  static bool get isCursorTeleporting =>
      SuperFocusManager.instance.state.cursorTeleportingNotifier.value;

  /// 判断当前输入系统是否应该处于锁定状态
  static bool get isInputLocked =>
      isCursorWaiting ||
      isCursorTeleporting ||
      SuperFocusManager.instance.intentionRoomId.value != null;

  /// 手动请求返回
  static void dispatchBack(BuildContext context) {
    SuperFocusManager.instance.onBack(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 设备管理模块专用接口（由 DeviceManager 调用）
  // ─────────────────────────────────────────────────────────────────────────

  /// 【移动指令】向指定方向移动焦点
  static void dispatchMove(TraversalDirection direction) {
    SuperFocusManager.instance.onMove(direction);
  }

  /// 【确认指令】触发当前聚焦项的 onPressed 及导航动作
  static void dispatchConfirm() {
    SuperFocusManager.instance.onConfirm();
  }

  /// 设置游标进入等待加载状态 (显示转圈/虚线动效)
  static void setCursorWaiting(bool isWaiting) {
    SuperFocusManager.instance.setCursorWaiting(isWaiting);
  }

  /// 【返回指令】执行焦点回退（无需 BuildContext）
  static void dispatchBackCommand() {
    SuperFocusManager.instance.onBackCommand();
  }

  /// 【主页指令】回到初始状态
  static void dispatchHomeCommand() {
    SuperFocusManager.instance.onHomeCommand();
  }
}

/// 4. 【暴露状态】极其优雅的 BuildContext 扩展
extension FocusContextExt on BuildContext {
  /// 检查指定 ID 的房间或区域是否处于活跃状态
  bool useIsActive(String id, {bool isZone = false}) {
    FocusTopologyScope.of(this);
    return SuperFocusManager.instance.state.checkIsActive(id, isZone: isZone);
  }

  /// 检查当前焦点是否落在此 ID 上
  bool useIsFocused(String id) {
    FocusTopologyScope.of(this);
    return SuperFocusManager.instance.state.checkIsFocused(id);
  }
}
