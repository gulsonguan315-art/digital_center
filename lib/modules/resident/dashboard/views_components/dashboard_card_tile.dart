import 'package:flutter/material.dart';

import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/control/superfocus/focus_manager.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../engine/dashboard_controller.dart';
import '../engine/dashboard_models.dart';

/// 🧩 看板卡片磁贴 (Dashboard Card Tile View)
/// 独立管理单张磁贴的位置大小、插槽式组件加载、手势点按以及编辑状态边框。
class DashboardCardTile extends StatelessWidget {
  final DashboardItemConfig config;
  final DashboardController controller;
  final Map<String, Widget> slots;
  final double unitSize;
  final double gap;

  const DashboardCardTile({
    super.key,
    required this.config,
    required this.controller,
    required this.slots,
    required this.unitSize,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final rect = config.toRect(unitSize, gap);
    final isGrabbed = controller.grabbedItemId == config.id;

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
          borderRadius: material.shape.radius as BorderRadius,
        ),
        builder: (context, hasFocus) {
          // 1. 从外部传入的 slots 中按卡片 ID 取件渲染 (Render slot component)
          final Widget card = slots[config.id] ??
              Center(
                child: Text(
                  config.id.replaceAll('dash_', '').toUpperCase(),
                  style: TextStyle(
                    fontWeight: hasFocus ? FontWeight.w900 : FontWeight.bold,
                    color: hasFocus
                        ? (isGrabbed
                            ? Colors.orangeAccent
                            : material.colors.accent)
                        : material.colors.textPrimary.withValues(alpha: 0.2),
                    letterSpacing: 1.2,
                  ),
                ),
              );

          // 2. 交互手势与编辑状态包裹 (Interact Gestures Wrapper)
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // 正常或编辑模式下，点击任何卡片都应当先聚焦
              final nodeInfo =
                  SuperFocusManager.instance.state.nodeRegistry[config.id];
              if (nodeInfo != null) {
                nodeInfo.node.requestFocus();
              }

              if (controller.isEditMode) {
                controller.toggleGrabItem(config.id);
              } else {
                // 正常模式：触发默认 confirmation 动作
                SuperFocusManager.instance.onAction(
                  'dashboardPage',
                  config.id,
                );
              }
            },
            child: Stack(
              children: [
                Positioned.fill(child: card),
                // 编辑模式半透明橙边框/焦点黄金边框覆盖
                if (controller.isEditMode)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: material.shape.radius,
                          border: Border.all(
                            color: isGrabbed
                                ? Colors.orangeAccent
                                : (hasFocus
                                    ? material.colors.accent
                                    : material.colors.accent.withValues(
                                        alpha: 0.4,
                                      )),
                            width: isGrabbed ? 4 : 2,
                          ),
                          boxShadow: isGrabbed
                              ? [
                                  BoxShadow(
                                    color: Colors.orangeAccent.withValues(
                                      alpha: 0.4,
                                    ),
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
            ),
          );
        },
      ),
    );
  }
}
