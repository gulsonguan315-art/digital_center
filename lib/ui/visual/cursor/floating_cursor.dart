import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/control/superfocus/interaction_manager.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/control/superfocus/focus_geometry.dart';

class FloatingHighlightBox extends StatefulWidget {
  const FloatingHighlightBox({super.key});

  @override
  State<FloatingHighlightBox> createState() => _FloatingHighlightBoxState();
}

class _FloatingHighlightBoxState extends State<FloatingHighlightBox>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Rect? _liveRect;
  Rect? _lastValidRect;
  BuildContext? _currentTrackingContext;
  bool _isTransitioning = false;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    SuperFocusManager.instance.cursorReportNotifier.addListener(
      _handleServiceUpdate,
    );
    SuperFocusManager.instance.cursorHiddenNotifier.addListener(
      _handleServiceUpdate,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transitionTimer?.cancel();
    SuperFocusManager.instance.cursorReportNotifier.removeListener(
      _handleServiceUpdate,
    );
    SuperFocusManager.instance.cursorHiddenNotifier.removeListener(
      _handleServiceUpdate,
    );
    super.dispose();
  }

  void _handleServiceUpdate() {
    final report = SuperFocusManager.instance.cursorReportNotifier.value;
    if (report?.context != _currentTrackingContext) {
      _currentTrackingContext = report?.context;
      _isTransitioning = true;
      _transitionTimer?.cancel();
      _transitionTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _isTransitioning = false);
        }
      });
    }

    if (mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    final report = SuperFocusManager.instance.cursorReportNotifier.value;
    if (report == null || report.context == null) {
      return;
    }

    if (!report.context!.mounted) return;

    RenderBox? renderBox;
    try {
      renderBox = report.context!.findRenderObject() as RenderBox?;
    } catch (_) {
      return;
    }

    if (renderBox == null || !renderBox.hasSize || !renderBox.attached) {
      return;
    }

    final transform = renderBox.getTransformTo(null);
    final newRect = MatrixUtils.transformRect(
      transform,
      Offset.zero & renderBox.size,
    );

    Rect targetRect = newRect;

    // 向上遍历所有视口，依次应用“撞边卡住”逻辑
    // 这解决了嵌套 Viewport（如 GridView 嵌套在 CustomScrollView 中）时，外层边界约束失效导致焦点飞出的问题。
    RenderBox? currentBox = renderBox;
    double totalDx = 0;
    double totalDy = 0;

    while (currentBox != null) {
      final viewport = RenderAbstractViewport.maybeOf(currentBox);
      if (viewport is RenderBox) {
        final viewportBox = viewport as RenderBox;
        final viewportTransform = viewportBox.getTransformTo(null);
        final viewportRect = MatrixUtils.transformRect(
          viewportTransform,
          Offset.zero & viewportBox.size,
        );

        double dx = 0;
        double dy = 0;

        if (targetRect.height <= viewportRect.height) {
          if (targetRect.top < viewportRect.top) {
            dy = viewportRect.top - targetRect.top;
          } else if (targetRect.bottom > viewportRect.bottom) {
            dy = viewportRect.bottom - targetRect.bottom;
          }
        }

        if (targetRect.width <= viewportRect.width) {
          if (targetRect.left < viewportRect.left) {
            dx = viewportRect.left - targetRect.left;
          } else if (targetRect.right > viewportRect.right) {
            dx = viewportRect.right - targetRect.right;
          }
        }

        if (dx != 0 || dy != 0) {
          targetRect = targetRect.shift(Offset(dx, dy));
          totalDx += dx;
          totalDy += dy;
        }

        // 继续往上找更外层的视口（如果有的话）
        currentBox = viewportBox.parent as RenderBox?;
      } else {
        break;
      }
    }

    // 自动推动外层滚动视图，实现“海报滚进来”的效果
    if (totalDx != 0 || totalDy != 0) {
      // 寻找能够响应滚动的最外层或有效 Scrollable
      BuildContext? ctx = report.context;
      ScrollableState? activeScrollable;
      while (ctx != null) {
        final s = Scrollable.maybeOf(ctx);
        if (s != null) {
          if (s.position.maxScrollExtent > s.position.minScrollExtent) {
            activeScrollable = s;
            break;
          }
          // 因为 Scrollable.maybeOf 找的是最近的，如果要找上一级，需要跨过当前 Scrollable
          // Flutter 树遍历技巧：从当前 Scrollable 的 parent 继续往上找
          ctx = _findParentContext(s.context);
        } else {
          break;
        }
      }

      if (activeScrollable != null) {
        final position = activeScrollable.position;
        double newPixels = position.pixels;

        // dy < 0 说明焦点框被向上挤压，说明实际元素在下方更深处，需要增加像素往下滚
        if (totalDy != 0) {
          newPixels -= totalDy * 0.15; // 平滑缓冲系数
        }
        if (totalDx != 0 && position.axis == Axis.horizontal) {
          newPixels -= totalDx * 0.15;
        }

        if (newPixels != position.pixels) {
          newPixels = newPixels.clamp(position.minScrollExtent, position.maxScrollExtent);
          position.jumpTo(newPixels);
        }
      }
    }

    bool isChanged = false;
    if (_liveRect == null) {
      isChanged = true;
    } else {
      final delta =
          (targetRect.left - _liveRect!.left).abs() +
          (targetRect.top - _liveRect!.top).abs() +
          (targetRect.width - _liveRect!.width).abs() +
          (targetRect.height - _liveRect!.height).abs();
      if (delta > 0.1) {
        isChanged = true;
      }
    }

    if (isChanged) {
      setState(() {
        _liveRect = targetRect;
        _lastValidRect = targetRect;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = SuperFocusManager.instance.cursorReportNotifier.value;
    final isActuallyHidden =
        SuperFocusManager.instance.cursorHiddenNotifier.value;
    final isVisible =
        !isActuallyHidden &&
        report != null &&
        report.isFocused &&
        _liveRect != null;

    if (isActuallyHidden) return const SizedBox.shrink();

    final opacity = isVisible ? 1.0 : 0.0;
    final osDpr = View.of(context).devicePixelRatio;
    final visualScale = 1.0 / osDpr;
    final targetRect = _liveRect ?? _lastValidRect ?? Rect.zero;
    final duration = _isTransitioning
        ? const Duration(milliseconds: 300)
        : Duration.zero;

    return ThemeIdentity(
      role: ThemeRole.appBackground,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();

          return IgnorePointer(
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  left: targetRect.left,
                  top: targetRect.top,
                  width: targetRect.width,
                  height: targetRect.height,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: opacity,
                    child: CustomPaint(
                      painter: _FocusOutlinePainter(
                        geometry: report?.geometry,
                        color: material.colors.accent,
                        visualScale: visualScale,
                        glowRadius: material.focusGlowRadius,
                        glowOpacity: material.focusGlowOpacity,
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

class _FocusOutlinePainter extends CustomPainter {
  const _FocusOutlinePainter({
    required this.geometry,
    required this.color,
    required this.visualScale,
    required this.glowRadius,
    required this.glowOpacity,
  });

  final FocusGeometry? geometry;
  final Color color;
  final double visualScale;
  final double glowRadius;
  final double glowOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = this.geometry;
    if (geometry == null) return;

    final rect = Offset.zero & size;
    final outlinePath = geometry.buildOutlinePath(rect);
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * visualScale
      ..color = color.withValues(alpha: glowOpacity)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        glowRadius * visualScale,
      );
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * visualScale
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawPath(outlinePath, shadowPaint);
    canvas.drawPath(outlinePath, linePaint);

    if (geometry is SidebarTileFocusGeometry) {
      final rightOpacity = (1.0 - geometry.openRightness).clamp(0.0, 1.0);
      if (rightOpacity > 0.0) {
        final rightPath = geometry.buildRightSegment(rect);
        canvas.drawPath(
          rightPath,
          shadowPaint..color = color.withValues(alpha: 0.3 * rightOpacity),
        );
        canvas.drawPath(
          rightPath,
          linePaint..color = color.withValues(alpha: rightOpacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FocusOutlinePainter oldDelegate) {
    return oldDelegate.geometry != geometry ||
        oldDelegate.color != color ||
        oldDelegate.visualScale != visualScale ||
        oldDelegate.glowRadius != glowRadius ||
        oldDelegate.glowOpacity != glowOpacity;
  }
}

BuildContext? _findParentContext(BuildContext context) {
  BuildContext? parent;
  context.visitAncestorElements((element) {
    parent = element;
    return false; // 只访问第一个祖先然后停止
  });
  return parent;
}
