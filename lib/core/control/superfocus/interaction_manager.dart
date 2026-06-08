import 'package:flutter/widgets.dart';
import 'focus_report.dart';
import 'interaction_state.dart';
import 'interaction_controller.dart';
import 'focus_controller.dart';
import 'mouse_controller.dart';
import 'building_map.dart';

class SuperInteractionManager {
  static final SuperInteractionManager instance = SuperInteractionManager._internal();
  SuperInteractionManager._internal();

  /// 焦点系统的 RAM (内存单元)
  final InteractionState state = InteractionState();

  // --- 控制器实例 ---
  late BaseInteractionController _controller;

  // --- 配置标识 ---
  bool isMouseMode = false;

  /// 初始化引擎并读取配置
  void init({String mode = 'focus'}) {
    isMouseMode = (mode == 'mouse');
    if (isMouseMode) {
      _controller = MouseController();
    } else {
      _controller = FocusController();
    }
    _controller.init(state);
  }

  // --- 兼容性代理 (指向 RAM 中的寄存器) ---
  /// 全局返回键拦截器队列
  final List<bool Function()> _backInterceptors = [];
  ValueNotifier<FocusTopology> get topologyNotifier => state.topologyNotifier;
  ValueNotifier<FocusReport?> get cursorReportNotifier =>
      state.cursorReportNotifier;
  ValueNotifier<bool> get cursorHiddenNotifier => state.cursorHiddenNotifier;
  ValueNotifier<bool> get cursorWaitingNotifier => state.cursorWaitingNotifier;
  String? get currentRoomId => state.currentRoomId;
  ValueNotifier<String?> get intentionRoomId => _controller.intentionRoomId;

  // 获取 policy
  FocusTraversalPolicy get policy {
    if (!isMouseMode && _controller is FocusController) {
      return (_controller as FocusController).policy;
    }
    // 鼠标模式下返回默认 policy 或简单的 policy
    return WidgetOrderTraversalPolicy();
  }

  // --- RAM 操作指令 ---
  void reportCursor(FocusReport report) {
    if (state.cursorReportNotifier.value == report) return;
    state.cursorReportNotifier.value = report;
  }

  void hideCursor() => state.cursorHiddenNotifier.value = true;
  void showCursor() => state.cursorHiddenNotifier.value = false;
  void clearCursor() => state.cursorReportNotifier.value = null;

  void setCursorWaiting(bool isWaiting) {
    if (state.cursorWaitingNotifier.value != isWaiting) {
      state.cursorWaitingNotifier.value = isWaiting;
      // 当处于 waiting 状态时，可以考虑临时锁定焦点系统防止乱跑
      if (isWaiting) {
        state.cursorHiddenNotifier.value = false; // 确保加载动画可见
      }
    }
  }

  void requestNextTransition(FocusTransitionMode mode, {Duration? delay}) {
    state.nextTransition = FocusTransitionConfig(mode, delay: delay);
  }

  FocusTransitionConfig? consumeNextTransition() {
    final config = state.nextTransition;
    state.nextTransition = null;
    return config;
  }

  void registerNode(
    String id,
    FocusNode node,
    String roomId, {
    VoidCallback? onPressed,
  }) {
    state.nodeRegistry[id] = FocusNodeInfo(node, roomId, onPressed: onPressed);
    _controller.onNodeRegistered(id);
  }

  void unregisterNode(String id, {FocusNode? node}) {
    if (node != null) {
      if (state.nodeRegistry[id]?.node == node) {
        state.nodeRegistry.remove(id);
      }
    } else {
      state.nodeRegistry.remove(id);
    }
  }

  void registerRoom(String id, {FocusTransitionConfig? transitionConfig}) {
    state.roomRegistry[id] = RoomInfo(transitionConfig: transitionConfig);
  }

  void unregisterRoom(String id) {
    state.roomRegistry.remove(id);
  }

  // ===========================================================================
  // 5. 拦截器注册 (Interceptor API)
  // ===========================================================================

  /// 注册全局返回键拦截器
  void registerBackInterceptor(bool Function() interceptor) {
    if (!_backInterceptors.contains(interceptor)) {
      _backInterceptors.add(interceptor);
    }
  }

  /// 移除全局返回键拦截器
  void unregisterBackInterceptor(bool Function() interceptor) {
    _backInterceptors.remove(interceptor);
  }

  // ===========================================================================
  // 6. 生命周期
  // ===========================================================================

  void onMove(TraversalDirection direction) => _controller.onMove(direction);

  void onConfirm() => _controller.onConfirm();

  void onBackCommand() {
    // 优先轮询拦截器，如果被消费则直接返回
    for (final interceptor in _backInterceptors.reversed) {
      if (interceptor()) {
        return;
      }
    }

    _controller.onBack();
  }

  void onHomeCommand() {
    _controller.onHome();
  }

  // 兼容旧接口
  void onBack(BuildContext context) => onBackCommand();

  void onPointerEnter(String targetId) => _controller.onPointerEnter(targetId);
  
  void onPointerClick(String targetId) => _controller.onPointerClick(targetId);

  /// 激活特定节点，在当前交互模式下统一分发，如果节点未注册则运行 fallback。
  void activateNode(String id, {VoidCallback? fallback}) {
    final info = state.nodeRegistry[id];
    if (info != null) {
      onPointerClick(id);
    } else {
      fallback?.call();
    }
  }

  void onRoomEnter(String roomId) => _controller.onRoomEnter(roomId);

  void onAction(String sourceRoom, String id, {bool asTerminalRoom = false}) {
    _controller.onAction(sourceRoom, id, asTerminalRoom: asTerminalRoom);
  }

  bool isZone(String id) => BuildingMap.isZone(id);
}

// 别名以维持兼容性
typedef SuperFocusManager = SuperInteractionManager;
