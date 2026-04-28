import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'focus_manager.dart';

/// 房间上下文，用于让内部组件感知自己属于哪个房间及其状态
class RoomScope extends InheritedWidget {
  final String roomId;
  final bool isActive;

  const RoomScope({
    required this.roomId,
    required this.isActive,
    required super.child,
    super.key,
  });

  static RoomScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RoomScope>();
  }

  @override
  bool updateShouldNotify(RoomScope oldWidget) =>
      roomId != oldWidget.roomId || isActive != oldWidget.isActive;
}

/// 房间包装组件 - UI "三步走"之第二步
///
/// 改为 StatefulWidget，以便在 initState 中缓存 isZone 的查询结果，
/// 避免每次 build 都触发一次全局 Map 遍历。
class SuperFocusRoom extends StatefulWidget {
  final String id;
  final Widget child;

  const SuperFocusRoom({super.key, required this.id, required this.child});

  @override
  State<SuperFocusRoom> createState() => _SuperFocusRoomState();
}

class _SuperFocusRoomState extends State<SuperFocusRoom> {
  /// [修复 2] isZone 结果只查询一次，字符串 ID 不会在运行时改变。
  late final bool _isZone;

  @override
  void initState() {
    super.initState();
    _isZone = SuperFocusManager.instance.isZone(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FocusTopology>(
      valueListenable: SuperFocusManager.instance.topologyNotifier,
      builder: (context, topology, _) {
        final activePath = topology.activePath;
        final parentScope = RoomScope.of(context);

        final bool isActive = _isZone
            ? (parentScope?.isActive ?? activePath.contains(widget.id))
            : activePath.contains(widget.id);

        final Widget roomWidget = RoomScope(
          roomId: widget.id,
          isActive: isActive,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                // Zone 与 Room 统一：都上报自身 ID。
                // _fillPath 会通过规范化 key（去掉 +）正确追溯祖先链，
                // 从而使 activeRoomPath 包含 Zone 及其所有父级房间。
                SuperFocusManager.instance.onRoomEnter(widget.id);
              }
            },
            onKeyEvent: _isZone
                ? null
                : (node, event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.escape ||
                            event.logicalKey == LogicalKeyboardKey.backspace)) {
                      SuperFocusManager.instance.onBack(context);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
            child: widget.child,
          ),
        );

        if (!_isZone) {
          return FocusScope(debugLabel: 'Room-${widget.id}', child: roomWidget);
        }
        return roomWidget;
      },
    );
  }
}

/// 区域包装组件 - 用于房间内的嵌套区域
class SuperFocusGroup extends StatelessWidget {
  final String id;
  final Widget child;

  const SuperFocusGroup({super.key, required this.id, required this.child});

  @override
  Widget build(BuildContext context) {
    final parentScope = RoomScope.of(context);
    return RoomScope(
      roomId: id,
      isActive: parentScope?.isActive ?? false,
      child: child,
    );
  }
}

/// 焦点原子项 - UI "三步走"之第三步
class SuperFocusItem extends StatefulWidget {
  final String id;
  final Widget Function(BuildContext context, bool hasFocus) builder;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  const SuperFocusItem({
    super.key,
    required this.id,
    required this.builder,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<SuperFocusItem> createState() => _SuperFocusItemState();
}

class _SuperFocusItemState extends State<SuperFocusItem> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  /// [修复 1] 记录上一次注册时使用的 roomId。
  /// didChangeDependencies 可能因父级 InheritedWidget（如 RoomScope）的变化而被
  /// 频繁触发，但我们只在 roomId 真正发生变化时才重新注册，杜绝海量冗余回调。
  String? _registeredRoomId;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final room = RoomScope.of(context);
    if (room != null && room.roomId != _registeredRoomId) {
      SuperFocusManager.instance.registerNode(
        widget.id,
        _focusNode,
        room.roomId,
      );
      _registeredRoomId = room.roomId;
    }
  }

  @override
  void dispose() {
    SuperFocusManager.instance.unregisterNode(widget.id);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focus) => setState(() => _hasFocus = focus),
      onKeyEvent: (node, event) {
        // 先检查导航协议拦截
        final protocolResult = SuperFocusManager.instance.handleKeyEvent(
          node,
          event,
        );
        if (protocolResult == KeyEventResult.handled) return protocolResult;

        // 业务动作触发
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          if (widget.onPressed != null) widget.onPressed!();

          final String sourceRoom =
              RoomScope.of(context)?.roomId ??
              SuperFocusManager.instance.currentRoomId ??
              '未知';
          if (sourceRoom != '未知') {
            SuperFocusManager.instance.onAction(sourceRoom, widget.id);
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.builder(context, _hasFocus),
    );
  }
}
