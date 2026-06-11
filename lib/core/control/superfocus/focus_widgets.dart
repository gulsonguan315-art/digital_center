import 'package:flutter/widgets.dart';
import 'interaction_state.dart';
import 'interaction_manager.dart';
import 'focus_geometry.dart';
import 'focus_report.dart';
import 'auto_scroll_dispatcher.dart';
import '../device_manager/device_manager.dart';
import 'focus_alignment.dart';

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
  final FocusTransitionConfig? transitionConfig;

  const SuperFocusRoom({
    super.key,
    required this.id,
    required this.child,
    this.transitionConfig,
  });

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
    SuperFocusManager.instance.registerRoom(
      widget.id,
      transitionConfig: widget.transitionConfig,
    );
  }

  @override
  void didUpdateWidget(SuperFocusRoom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id ||
        widget.transitionConfig != oldWidget.transitionConfig) {
      SuperFocusManager.instance.registerRoom(
        widget.id,
        transitionConfig: widget.transitionConfig,
      );
    }
  }

  @override
  void dispose() {
    SuperFocusManager.instance.unregisterRoom(widget.id);
    super.dispose();
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
                    if (!mounted) return;
                    final primaryContext =
                        FocusManager.instance.primaryFocus?.context;
                    if (primaryContext != null && primaryContext.mounted) {
                      final closestRoomId = RoomScope.of(
                        primaryContext,
                      )?.roomId;
                      // 只有当最深层的房间就是自己时，才上报。
                      // 防止嵌套房间（如 MediaDetailRoom 嵌套在 MediaRoom 中）在恢复焦点时父房间覆盖子房间。
                      if (closestRoomId == widget.id) {
                        SuperFocusManager.instance.onRoomEnter(widget.id);
                      }
                    }
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

/// 焦点簇（Focus Cluster）
/// 将一组连续的焦点项（如水平的 ListView/Row）包裹在这个组件中，
/// 它会在焦点引擎进行几何方向扫描时，形成一道物理隔离结界，优先让焦点在簇内流转，
/// 从而完美解决诸如“水平滚动列表右移时，因为高度视差错误跳跃到上方其它元素”的魔性问题。
class FocusCluster extends StatelessWidget {
  final Widget child;

  const FocusCluster({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      debugLabel: 'FocusCluster',
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
  final FocusAlignment alignment;

  const SuperFocusItem({
    super.key,
    required this.id,
    required this.builder,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.focusGeometry,
    this.visualBoundsKey,
    this.alignment = FocusAlignment.keepVisible,
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

    // 列表元素被复用时，id 会发生变化，必须注销旧 ID
    if (oldWidget.id != widget.id) {
      SuperFocusManager.instance.unregisterNode(oldWidget.id, node: _focusNode);
      if (_registeredRoomId != null) {
        SuperFocusManager.instance.registerNode(
          widget.id,
          _focusNode,
          _registeredRoomId!,
          onPressed: widget.onPressed,
        );
      }
    } else if (oldWidget.onPressed != widget.onPressed &&
        _registeredRoomId != null) {
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
    SuperFocusManager.instance.unregisterNode(widget.id, node: _focusNode);
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

      final config = SuperFocusManager.instance.consumeNextTransition();

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
          transitionMode: config?.mode ?? FocusTransitionMode.slide,
          teleportDelay: config?.delay,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMouseMode = SuperInteractionManager.instance.isMouseMode;
    return MouseRegion(
      onEnter: (_) =>
          SuperInteractionManager.instance.onPointerEnter(widget.id),
      cursor: isMouseMode ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          SuperInteractionManager.instance.onPointerClick(widget.id);
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
              _reportFocus();
              // ！！！核心修复 3：确保所有常规方向键移动都会触发自定义滚动引擎 ！！！
              AutoScrollDispatcher.ensureVisible(
                context,
                alignment: widget.alignment,
              );
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
  bool _hadFocus = false;

  @override
  void dispose() {
    if (_hadFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SuperFocusManager.instance.showCursor();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = RoomScope.of(context);
    final id = room != null ? '${room.roomId}_air_node' : 'global_air_node';

    return SuperFocusItem(
      id: id,
      builder: (context, hasFocus) {
        _hadFocus = hasFocus;
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

/// 统一的焦点/鼠标动作按钮组件 (Unified Focus Action Button Component)
class FocusActionButton extends StatelessWidget {
  final String id;
  final VoidCallback onPressed;
  final FocusGeometry? focusGeometry;
  final Widget Function(
    BuildContext context,
    bool hasFocus,
    VoidCallback activate,
  )
  builder;

  const FocusActionButton({
    super.key,
    required this.id,
    required this.onPressed,
    required this.builder,
    this.focusGeometry,
  });

  @override
  Widget build(BuildContext context) {
    return FocusIdentity(
      id: id,
      onPressed: onPressed,
      focusGeometry: focusGeometry,
      builder: (context, hasFocus) {
        return ExcludeFocus(
          child: builder(context, hasFocus, () {
            SuperInteractionManager.instance.activateNode(
              id,
              fallback: onPressed,
            );
          }),
        );
      },
    );
  }
}

/// 鼠标模式背景点击关闭区域 (Mouse Dismiss Region)
class MouseDismissRegion extends StatelessWidget {
  final VoidCallback onDismiss;
  final Widget child;

  const MouseDismissRegion({
    super.key,
    required this.onDismiss,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (SuperInteractionManager.instance.isMouseMode) {
          onDismiss();
        }
      },
      child: child,
    );
  }
}
