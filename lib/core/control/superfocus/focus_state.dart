import 'package:flutter/widgets.dart';
import 'focus_report.dart';

/// 焦点状态快照 - 存储“当前在哪”
class FocusTopology {
  final String? activeRoom;
  final Set<String> activePath;

  const FocusTopology({this.activeRoom, this.activePath = const {}});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusTopology &&
          activeRoom == other.activeRoom &&
          activePath == other.activePath;

  @override
  int get hashCode => Object.hash(activeRoom, activePath);
}

/// 节点注册信息
class FocusNodeInfo {
  final FocusNode node;
  final String roomId;
  /// 节点对应的确认动作回调（由 DeviceManager 的 confirm 信号触发）
  final VoidCallback? onPressed;
  FocusNodeInfo(this.node, this.roomId, {this.onPressed});
}

/// 传送门回溯信息
class PortalEntry {
  final String landedIn;
  final String returnTo;
  final FocusNode? returnToFocusNode;
  const PortalEntry({
    required this.landedIn,
    required this.returnTo,
    this.returnToFocusNode,
  });
}

/// 焦点系统的 RAM (智能存储单元)
/// 负责：存储原始数据、维护通知器、提供状态翻译逻辑
class FocusState {
  // --- 静态存储 (数据表) ---
  final Map<String, FocusNodeInfo> nodeRegistry = {};
  final List<PortalEntry> portalStack = [];

  // --- 核心状态通知器 (寄存器) ---
  final ValueNotifier<FocusTopology> topologyNotifier = ValueNotifier(
    const FocusTopology(),
  );
  final ValueNotifier<FocusReport?> cursorReportNotifier = ValueNotifier(null);
  final ValueNotifier<bool> cursorHiddenNotifier = ValueNotifier(false);

  // --- 翻译逻辑 (Translation Logic) ---

  /// 翻译：判断指定 ID 的房间或区域是否处于活跃路径上
  bool checkIsActive(String id, {bool isZone = false}) {
    final path = topologyNotifier.value.activePath;
    if (isZone) {
      return path.contains(id);
    }
    // 兼容 Page 后缀业务逻辑
    return path.contains(id) || path.contains('${id}Page');
  }

  /// 翻译：判断指定 ID 是否是当前活跃房间
  bool checkIsFocused(String id) {
    return topologyNotifier.value.activeRoom == id;
  }

  /// 获取当前活跃房间 ID
  String? get currentRoomId => topologyNotifier.value.activeRoom;

  /// 清理方法
  void dispose() {
    topologyNotifier.dispose();
    cursorReportNotifier.dispose();
    cursorHiddenNotifier.dispose();
  }
}
