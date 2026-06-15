import 'package:flutter/material.dart';

import '../../../../core/control/superfocus/focus_api.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_manager.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../engine/dashboard_controller.dart';
import '../engine/dashboard_models.dart';

/// 🧩 看板卡片磁贴 (Dashboard Card Tile View)
/// 独立管理单张磁贴的位置大小、插槽式组件加载、手势点按以及编辑状态边框。
class DashboardCardTile extends StatefulWidget {
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
  State<DashboardCardTile> createState() => _DashboardCardTileState();
}

class _DashboardCardTileState extends State<DashboardCardTile> {
  // 用于拖拽的初始快照
  int? _dragStartX;
  int? _dragStartY;
  int? _dragStartSpanX;
  int? _dragStartSpanY;
  Offset? _dragStartPointer;
  bool _isMouseDragging = false;

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final rect = widget.config.toRect(widget.unitSize, widget.gap);
    final isGrabbed = widget.controller.grabbedItemId == widget.config.id;
    // 如果正在鼠标拖拽，则取消动画时间以保持鼠标跟手（虽然是网格吸附，但零延迟响应更好）
    final animationDuration =
        _isMouseDragging ? Duration.zero : const Duration(milliseconds: 300);

    return AnimatedPositioned(
      key: ValueKey(widget.config.id),
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: FocusIdentity(
        id: widget.config.id,
        focusGeometry: RoundedRectFocusGeometry(
          borderRadius: material.shape.radius as BorderRadius,
        ),
        builder: (context, hasFocus) {
          // 1. 从外部传入的 slots 中按卡片 ID 取件渲染 (Render slot component)
          final Widget card = widget.slots[widget.config.id] ??
              Center(
                child: Text(
                  widget.config.id.replaceAll('dash_', '').toUpperCase(),
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
                  SuperFocusManager.instance.state.nodeRegistry[widget.config.id];
              if (nodeInfo != null) {
                nodeInfo.node.requestFocus();
              }

              if (widget.controller.isEditMode) {
                widget.controller.toggleGrabItem(widget.config.id);
              } else {
                // 正常模式：触发默认 confirmation 动作
                SuperFocusManager.instance.onAction(
                  'dashboardPage',
                  widget.config.id,
                );
              }
            },
            // --- 【鼠标拖拽移动逻辑】 ---
            onPanStart: widget.controller.isEditMode
                ? (details) {
                    setState(() {
                      _isMouseDragging = true;
                      _dragStartX = widget.config.x;
                      _dragStartY = widget.config.y;
                      _dragStartPointer = details.globalPosition;
                    });
                  }
                : null,
            onPanUpdate: widget.controller.isEditMode && _isMouseDragging
                ? (details) {
                    if (_dragStartPointer == null ||
                        _dragStartX == null ||
                        _dragStartY == null) return;
                    
                    final delta = details.globalPosition - _dragStartPointer!;
                    final cellTotalSize = widget.unitSize + widget.gap;
                    
                    final int deltaGridX = (delta.dx / cellTotalSize).round();
                    final int deltaGridY = (delta.dy / cellTotalSize).round();
                    
                    if (deltaGridX != 0 || deltaGridY != 0) {
                      widget.controller.updateItemPosition(
                        widget.config.id,
                        _dragStartX! + deltaGridX,
                        _dragStartY! + deltaGridY,
                      );
                    }
                  }
                : null,
            onPanEnd: widget.controller.isEditMode
                ? (details) {
                    setState(() {
                      _isMouseDragging = false;
                      _dragStartX = null;
                      _dragStartY = null;
                      _dragStartPointer = null;
                    });
                    widget.controller.finalizeLayout();
                  }
                : null,
            // ------------------------
            child: Stack(
              children: [
                Positioned.fill(child: card),
                  // 编辑模式半透明橙边框/焦点黄金边框覆盖
                if (widget.controller.isEditMode)
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

                // 3. 鼠标缩放把手 (Resize Handle for Mouse)
                if (widget.controller.isEditMode)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _isMouseDragging = true;
                          _dragStartSpanX = widget.config.spanX;
                          _dragStartSpanY = widget.config.spanY;
                          _dragStartPointer = details.globalPosition;
                        });
                      },
                      onPanUpdate: (details) {
                        if (_dragStartPointer == null ||
                            _dragStartSpanX == null ||
                            _dragStartSpanY == null) return;

                        final delta = details.globalPosition - _dragStartPointer!;
                        final cellTotalSize = widget.unitSize + widget.gap;

                        final int deltaGridX = (delta.dx / cellTotalSize).round();
                        final int deltaGridY = (delta.dy / cellTotalSize).round();

                        if (deltaGridX != 0 || deltaGridY != 0) {
                          widget.controller.updateItemSpan(
                            widget.config.id,
                            _dragStartSpanX! + deltaGridX,
                            _dragStartSpanY! + deltaGridY,
                          );
                        }
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _isMouseDragging = false;
                          _dragStartSpanX = null;
                          _dragStartSpanY = null;
                          _dragStartPointer = null;
                        });
                        widget.controller.finalizeLayout();
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.transparent, // 扩大点击区域
                        ),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(
                            Icons.open_in_full_rounded,
                            size: 16,
                            color: material.colors.accent.withValues(alpha: 0.8),
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
    );
  }
}
