import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
import '../../../ui/base/surface/dashboard_card.dart';
import '../../widgets/clock/clock_view.dart';
import 'dashboard_callback.dart';
import 'engine/dashboard_controller.dart';
import 'engine/dashboard_models.dart';

/// DashboardView renders the grid of cards using DashboardController.
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

    // 初始化一些测试数据
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
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.contextMenu):
            const _ToggleEditModeIntent(),
        const SingleActivator(LogicalKeyboardKey.f10):
            const _ToggleEditModeIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _ToggleEditModeIntent: CallbackAction<_ToggleEditModeIntent>(
            onInvoke: (_) {
              debugPrint('--- [DASHBOARD] Menu Key Pressed! ---');
              _controller.setEditMode(!_controller.isEditMode);
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double unitSize = context.units(15);
            final double gap = context.units(2);

            return ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Stack(
                  key: _gridKey,
                  clipBehavior: Clip.none,
                  children: [
                    // 编辑模式提示标签
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
                              color: context.useTheme().colors.accent,
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

                    // 卡片列表
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
                              DashboardCallback.onInteractionEnd(_controller),
                          child: SuperFocusItem(
                            id: config.id,
                            focusGeometry: RoundedRectFocusGeometry(
                              borderRadius: Theme.of(
                                context,
                              ).extension<AppTheme>()!.shapes.card.radius,
                            ),
                            builder: (context, hasFocus) {
                              Widget content;
                              if (config.id == 'dash_clock') {
                                content = const ClockView();
                              } else {
                                content = Center(
                                  child: Text(
                                    config.id
                                        .replaceAll('dash_', '')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: hasFocus
                                          ? FontWeight.w900
                                          : FontWeight.bold,
                                      color: hasFocus
                                          ? context.useTheme().colors.accent
                                          : null,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                );
                              }

                              return DashboardCard(
                                padding: EdgeInsets.zero,
                                child: Stack(
                                  children: [
                                    Positioned.fill(child: content),

                                    // 编辑状态的边框
                                    if (_controller.isEditMode)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: Theme.of(context)
                                                .extension<AppTheme>()!
                                                .shapes
                                                .card
                                                .radius,
                                            border: Border.all(
                                              color: context
                                                  .useTheme()
                                                  .colors
                                                  .accent
                                                  .withValues(alpha: 0.4),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),

                                    // 缩放手柄
                                    if (_controller.isEditMode)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
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
                                            color: Colors.transparent, // 扩大热区
                                            child: Center(
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: context
                                                      .useTheme()
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
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
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
