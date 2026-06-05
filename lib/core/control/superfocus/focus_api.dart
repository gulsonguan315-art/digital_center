library focus_api;

import 'package:flutter/material.dart';
import 'interaction_manager.dart';
import 'focus_widgets.dart';

// 1. 【暴露组件】
export 'focus_widgets.dart'
    show SuperFocusRoom, FocusIdentity, FocusShape, FocusTopologyScope, FocusActionButton, MouseDismissRegion;

// 2. 【暴露模型】
export 'interaction_state.dart' show FocusTopology;
export 'focus_geometry.dart'
    show FocusGeometry, RoundedRectFocusGeometry, SidebarTileFocusGeometry;

/// 3. 【暴露命令】UI 发号施令的唯一遥控器
abstract class FocusAPI {
  /// 发送焦点动作意图
  /// [asTerminalRoom] - 如果进入的是一个死胡同/预览房间，设置为 true 可阻断动态子房间继承
  static void dispatchAction(String currentRoom, String id, {bool asTerminalRoom = false}) {
    SuperFocusManager.instance.onAction(currentRoom, id, asTerminalRoom: asTerminalRoom);
  }

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

  /// 【返回指令】执行焦点回退（无需 BuildContext）
  static void dispatchBackCommand() {
    SuperFocusManager.instance.onBackCommand();
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
