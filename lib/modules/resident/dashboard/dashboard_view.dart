import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
import '../../widgets/clock/clock_view.dart';
import 'dashboard_callback.dart';
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
                      return Stack(
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
                                    color: material.colors.accent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'DASHBOARD EDITING',
                                    style: TextStyle(
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

                            return AnimatedPositioned(
                              key: ValueKey(config.id),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              left: rect.left,
                              top: rect.top,
                              width: rect.width,
                              height: rect.height,
                              child: GestureDetector(
                                onPanUpdate: (details) =>
                                    DashboardCallback.onItemDrag(
                                      controller: _controller,
                                      gridKey: _gridKey,
                                      details: details,
                                      id: config.id,
                                      unitSize: unitSize,
                                      gap: gap,
                                    ),
                                onPanEnd: (_) =>
                                    DashboardCallback.onInteractionEnd(
                                      _controller,
                                    ),
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
                                                  ? material.colors.accent
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
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      material.shape.radius,
                                                  border: Border.all(
                                                    color: material
                                                        .colors
                                                        .accent
                                                        .withValues(alpha: 0.4),
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        // 编辑模式的缩放手柄
                                        if (_controller.isEditMode)
                                          Positioned(
                                            right: 8,
                                            bottom: 8,
                                            child: GestureDetector(
                                              onPanUpdate: (details) =>
                                                  DashboardCallback.onItemResize(
                                                    controller: _controller,
                                                    gridKey: _gridKey,
                                                    details: details,
                                                    config: config,
                                                    rect: rect,
                                                    unitSize: unitSize,
                                                    gap: gap,
                                                  ),
                                              onPanEnd: (_) =>
                                                  DashboardCallback.onInteractionEnd(
                                                    _controller,
                                                  ),
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                color: Colors.transparent,
                                                child: Center(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: material
                                                          .colors
                                                          .accent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.unfold_more_rounded,
                                                      size: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
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
