import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/control/superfocus/focus_manager.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
import '../../widgets/clock/clock_view.dart';
import 'engine/dashboard_controller.dart';
import 'engine/dashboard_models.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardController _controller;
  final GlobalKey _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.setItems([
      const DashboardItemConfig(
        id: 'dash_weather',
        x: 0,
        y: 0,
        spanX: 2,
        spanY: 2,
      ),
      const DashboardItemConfig(
        id: 'dash_music',
        x: 2,
        y: 1,
        spanX: 1,
        spanY: 1,
      ),
      const DashboardItemConfig(
        id: 'dash_clock',
        x: 2,
        y: 0,
        spanX: 2,
        spanY: 1,
      ),
      const DashboardItemConfig(
        id: 'dash_stats',
        x: 3,
        y: 1,
        spanX: 1,
        spanY: 1,
      ),
      const DashboardItemConfig(
        id: 'dash_lights',
        x: 0,
        y: 2,
        spanX: 4,
        spanY: 1,
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.contextMenu):
            _ToggleEditModeIntent(),
        SingleActivator(LogicalKeyboardKey.f10): _ToggleEditModeIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ToggleEditModeIntent: CallbackAction<_ToggleEditModeIntent>(
            onInvoke: (_) {
              _controller.setEditMode(!_controller.isEditMode);
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final unitSize = context.units(15);
            final gap = context.units(2);

            return ThemeIdentity(
              role: ThemeRole.card,
              child: Builder(
                builder: (context) {
                  final material = context.useTheme();

                  return ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      final String? grabbedItemId = _controller.grabbedItemId;

                      return Focus(
                        autofocus: true,
                        onKeyEvent: (node, event) {
                          if (!_controller.isEditMode) return KeyEventResult.ignored;
                          if (event is KeyUpEvent) return KeyEventResult.ignored;

                          final logicalKey = event.logicalKey;
                          
                          // 获取当前聚焦卡片的物理 ID
                          final focusedId = SuperFocusManager.instance.state.nodeRegistry.entries
                              .where((e) => e.value.node.hasPrimaryFocus)
                              .firstOrNull
                              ?.key;
                              
                          if (focusedId == null) return KeyEventResult.ignored;

                          // 1. 如果按下确认键 (Enter / Space)：切换抓取/放置状态
                          if (logicalKey == LogicalKeyboardKey.enter || 
                              logicalKey == LogicalKeyboardKey.space ||
                              logicalKey == LogicalKeyboardKey.select) {
                            _controller.toggleGrabItem(focusedId);
                            return KeyEventResult.handled;
                          }

                          // 2. 如果当前有任何卡片被“抓取”，则拦截按键输入并执行位移与缩放
                          if (_controller.grabbedItemId != null) {
                            // 极限制守卫：只有被抓取的卡片才能消费按键事件，防止焦点中途飘走
                            if (focusedId != _controller.grabbedItemId) {
                              return KeyEventResult.handled;
                            }

                            final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
                            final itemIndex = _controller.items.indexWhere((item) => item.id == focusedId);
                            if (itemIndex == -1) return KeyEventResult.handled;
                            final item = _controller.items[itemIndex];

                            if (isShiftPressed) {
                              // Shift + 方向键 -> 缩放大小 (spanX, spanY)
                              int newSpanX = item.spanX;
                              int newSpanY = item.spanY;

                              if (logicalKey == LogicalKeyboardKey.arrowLeft) {
                                newSpanX = (item.spanX - 1).clamp(1, 12);
                              } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
                                newSpanX = (item.spanX + 1).clamp(1, 12);
                              } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
                                newSpanY = (item.spanY - 1).clamp(1, 12);
                              } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
                                newSpanY = (item.spanY + 1).clamp(1, 12);
                              } else {
                                return KeyEventResult.ignored;
                              }

                              _controller.updateItemSpan(focusedId, newSpanX, newSpanY);
                              return KeyEventResult.handled;
                            } else {
                              // 普通方向键 -> 平移位置 (x, y)
                              int newX = item.x;
                              int newY = item.y;

                              if (logicalKey == LogicalKeyboardKey.arrowLeft) {
                                newX = (item.x - 1).clamp(0, 11);
                              } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
                                newX = (item.x + 1).clamp(0, 11);
                              } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
                                newY = (item.y - 1).clamp(0, 100);
                              } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
                                newY = (item.y + 1).clamp(0, 100);
                              } else {
                                return KeyEventResult.ignored;
                              }

                              _controller.updateItemPosition(focusedId, newX, newY);
                              return KeyEventResult.handled;
                            }
                          }

                          return KeyEventResult.ignored;
                        },
                        child: Stack(
                          key: _gridKey,
                          clipBehavior: Clip.none,
                          children: [
                            if (_controller.isEditMode)
                              Positioned(
                                top: -40,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _controller.grabbedItemId != null
                                          ? Colors.orangeAccent
                                          : material.colors.accent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: _controller.grabbedItemId != null
                                          ? [
                                              BoxShadow(
                                                color: Colors.orangeAccent.withValues(alpha: 0.3),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      _controller.grabbedItemId != null
                                          ? 'GRABBED & MOVING...'
                                          : 'DASHBOARD EDITING (ENTER TO GRAB)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ..._controller.items.map((config) {
                              final rect = config.toRect(unitSize, gap);
                              final isGrabbed = grabbedItemId == config.id;

                              return AnimatedPositioned(
                                key: ValueKey(config.id),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                left: rect.left,
                                top: rect.top,
                                width: rect.width,
                                height: rect.height,
                                child: FocusIdentity(
                                  id: config.id,
                                  focusGeometry: RoundedRectFocusGeometry(
                                    borderRadius:
                                        material.shape.radius as BorderRadius,
                                  ),
                                  builder: (context, hasFocus) {
                                    // 1. 业务组件地图：DashboardView 只负责查表，不负责画画
                                    final Map<String, Widget> registry = {
                                      'dash_clock': const ClockView(),
                                      // 以后这里可以加 'dash_weather': const WeatherView(), 等
                                    };

                                    // 2. 获取组件：如果地图里没有，就直接显示文字（不干预任何效果，不领盘子）
                                    final Widget card =
                                        registry[config.id] ??
                                        Center(
                                          child: Text(
                                            config.id
                                                .replaceAll('dash_', '')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: hasFocus
                                                  ? FontWeight.w900
                                                  : FontWeight.bold,
                                              color: hasFocus
                                                  ? (isGrabbed
                                                      ? Colors.orangeAccent
                                                      : material.colors.accent)
                                                  : material.colors.textPrimary
                                                        .withValues(alpha: 0.2),
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        );

                                    // 3. 装饰层：只负责叠加框架逻辑（编辑模式等）
                                    return Stack(
                                      children: [
                                        Positioned.fill(child: card),
                                        // 编辑模式的半透明边框覆盖
                                        if (_controller.isEditMode)
                                          Positioned.fill(
                                            child: IgnorePointer(
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      material.shape.radius,
                                                  border: Border.all(
                                                    color: isGrabbed
                                                        ? Colors.orangeAccent
                                                        : (hasFocus
                                                            ? material.colors.accent
                                                            : material.colors.accent.withValues(alpha: 0.4)),
                                                    width: isGrabbed ? 4 : 2,
                                                  ),
                                                  boxShadow: isGrabbed
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.orangeAccent.withValues(alpha: 0.4),
                                                            blurRadius: 12,
                                                            spreadRadius: 2,
                                                          )
                                                        ]
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ToggleEditModeIntent extends Intent {
  const _ToggleEditModeIntent();
}
