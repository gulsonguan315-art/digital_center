import 'package:flutter/material.dart';

import '../../../core/data/data_manager.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
import '../../../core/control/device_manager/device_manager.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import 'dashboard_model.dart';
import 'engine/dashboard_controller.dart';
import 'views_components/dashboard_card_tile.dart';
import 'views_components/dashboard_edit_listener.dart';

/// 🖥️ 看板排版总视图 (Dashboard View Coordinator)
/// 纯排版布局工具，统一通过 [slots] 接收外部注入的具体组件挂件，实现高度解耦的填空排版。
class DashboardView extends StatefulWidget {
  final Map<String, Widget> slots;

  const DashboardView({
    super.key,
    required this.slots,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardController _controller;
  final GlobalKey _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(DataManager.instance);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                  return InputInterceptor(
                    onSignal: (signal) {
                      if (signal == InputSignal.menu) {
                        _controller.setEditMode(!_controller.isEditMode);
                        return true;
                      }
                      return false;
                    },
                    child: DashboardEditListener(
                      controller: _controller,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onSecondaryTap: () {
                          _controller.setEditMode(!_controller.isEditMode);
                        },
                      child: Stack(
                        key: _gridKey,
                        clipBehavior: Clip.none,
                        children: [
                        // 1. 编辑状态横幅提示 (Edit Mode Top Indicator)
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
                                            color: Colors.orangeAccent
                                                .withValues(alpha: 0.3),
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

                        // 2. 看板磁贴列表组件映射 (Dashboard grid cards)
                        ..._controller.items
                            .where(
                              (config) =>
                                  config.enabled ||
                                  config.id == DashboardModel.widgetManagerCardId,
                            )
                            .map((config) {
                              return DashboardCardTile(
                                key: ValueKey(config.id),
                                config: config,
                                controller: _controller,
                                slots: widget.slots,
                                unitSize: unitSize,
                                gap: gap,
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                );
              },
              );
            },
          ),
        );
      },
    );
  }
}
