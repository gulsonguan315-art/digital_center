import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'interaction_state.dart';
import 'interaction_manager.dart';
import 'focus_geometry.dart';
import 'focus_report.dart';
import '../device_manager/device_manager.dart';
import '../../log/log_api.dart';

typedef FocusShape = RoundedRectFocusGeometry;
typedef FocusIdentity = SuperFocusItem;

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

/// 拓扑状态作用域，支持 context.useIsActive 的响应式核心
class FocusTopologyScope extends InheritedWidget {
  final FocusTopology topology;

  const FocusTopologyScope({
    required this.topology,
    required super.child,
    super.key,
  });

  static FocusTopology of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FocusTopologyScope>();
    return scope?.topology ?? const FocusTopology();
  }

  @override
  bool updateShouldNotify(FocusTopologyScope oldWidget) =>
      topology != oldWidget.topology;
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

        // 在这里注入拓扑作用域，让子孙可以通过 context 访问并监听
        final Widget roomWidget = FocusTopologyScope(
          topology: topology,
          child: RoomScope(
            roomId: widget.id,
            isActive: isActive,
            child: Focus(
              canRequestFocus: false, // 房间本身不参与焦点竞争
              onFocusChange: (hasFocus) {
                if (hasFocus) {
                  // 异步上报，彻底解决 Build 周期内的重绘死循环
                  Future.microtask(() {
                    SuperFocusManager.instance.onRoomEnter(widget.id);
                  });
                }
              },
              // 按键监听已移交 DeviceManager 统一处理，此处不参与按键监听
              child: widget.child,
            ),
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
  final FocusGeometry? focusGeometry;
  final GlobalKey? visualBoundsKey;
  final bool ensureVisibleCentered;

  const SuperFocusItem({
    super.key,
    required this.id,
    required this.builder,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.focusGeometry,
    this.visualBoundsKey,
    this.ensureVisibleCentered = false,
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
        onPressed: widget.onPressed, // 向管理中心注册动作回调
      );
      _registeredRoomId = room.roomId;
    }
  }

  @override
  void didUpdateWidget(SuperFocusItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 【修复：ListView 复用元素导致旧 ID 残留】
    // 列表元素被复用时，id 会发生变化，必须注销旧 ID
    if (oldWidget.id != widget.id) {
      SuperFocusManager.instance.unregisterNode(oldWidget.id);
      if (_registeredRoomId != null) {
        SuperFocusManager.instance.registerNode(
          widget.id,
          _focusNode,
          _registeredRoomId!,
          onPressed: widget.onPressed,
        );
      }
    } else if (oldWidget.onPressed != widget.onPressed && _registeredRoomId != null) {
      // 【修复：Stale Closure】父组件 setState 可能传入全新的 onPressed 闭包
      SuperFocusManager.instance.registerNode(
        widget.id,
        _focusNode,
        _registeredRoomId!,
        onPressed: widget.onPressed,
      );
    }

    if (_hasFocus && oldWidget.focusGeometry != widget.focusGeometry) {
      _reportFocus();
    }
  }

  @override
  void dispose() {
    SuperFocusManager.instance.unregisterNode(widget.id);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _reportFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 【核心修复】：将 !_hasFocus 替换为 !_focusNode.hasPrimaryFocus
      // 绝对禁止父级“大门”因为焦点冒泡而抢夺子节点的游标！
      if (!mounted || !_focusNode.hasPrimaryFocus) return;

      final targetContext = widget.visualBoundsKey?.currentContext ?? context;
      final renderBox = targetContext.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;

      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      SuperFocusManager.instance.reportCursor(
        FocusReport(
          rect: offset & size,
          geometry:
              widget.focusGeometry ??
              const RoundedRectFocusGeometry(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
          isFocused: _hasFocus,
          context: context,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMouseMode = SuperInteractionManager.instance.isMouseMode;
    return MouseRegion(
      onEnter: (_) => SuperInteractionManager.instance.onPointerEnter(widget.id),
      cursor: isMouseMode ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (isMouseMode) {
            SuperInteractionManager.instance.onPointerClick(widget.id);
          }
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: widget.autofocus && !isMouseMode,
          canRequestFocus: !isMouseMode,
          onFocusChange: (focus) {
            setState(() => _hasFocus = focus);
            if (focus) {
              if (isMouseMode) {
                 // 补丁 2: 鼠标模式下切断确保居中以及强制游标上报
                 if (_focusNode.hasPrimaryFocus) {
                     _focusNode.unfocus();
                 }
                 return;
              }
              if (widget.ensureVisibleCentered) {
                Scrollable.ensureVisible(
                  context,
                  alignment: 0.5,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                );
              }
              _reportFocus();
            }
          },
          child: widget.builder(context, _hasFocus),
        ),
      ),
    );
  }
}

class InputInterceptor extends StatefulWidget {
  final bool Function(InputSignal signal) onSignal;
  final Widget child;

  const InputInterceptor({
    super.key,
    required this.onSignal,
    required this.child,
  });

  @override
  State<InputInterceptor> createState() => _InputInterceptorState();
}

class _InputInterceptorState extends State<InputInterceptor> {
  bool _isRegistered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isActive = RoomScope.of(context)?.isActive ?? true;
    _syncRegistration(isActive);
  }

  void _syncRegistration(bool shouldRegister) {
    if (shouldRegister && !_isRegistered) {
      SuperInputManager.instance.registerInterceptor(_handleSignal);
      _isRegistered = true;
    } else if (!shouldRegister && _isRegistered) {
      SuperInputManager.instance.unregisterInterceptor(_handleSignal);
      _isRegistered = false;
    }
  }

  @override
  void dispose() {
    _syncRegistration(false);
    super.dispose();
  }

  bool _handleSignal(InputSignal signal) {
    if (!mounted) return false;
    final isActive = RoomScope.of(context)?.isActive ?? true;
    if (!isActive) return false;
    return widget.onSignal(signal);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class SuperFocusAirNode extends StatefulWidget {
  const SuperFocusAirNode({super.key});

  @override
  State<SuperFocusAirNode> createState() => _SuperFocusAirNodeState();
}

class _SuperFocusAirNodeState extends State<SuperFocusAirNode> {
  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SuperFocusManager.instance.showCursor();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = RoomScope.of(context);
    final id = room != null ? '${room.roomId}_air_node' : 'global_air_node';

    return SuperFocusItem(
      id: id,
      builder: (context, hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (hasFocus) {
              SuperFocusManager.instance.hideCursor();
            } else {
              SuperFocusManager.instance.showCursor();
            }
          }
        });
        return const SizedBox.shrink();
      },
    );
  }
}
