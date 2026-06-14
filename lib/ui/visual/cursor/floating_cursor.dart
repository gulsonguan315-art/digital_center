import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import '../../../core/control/superfocus/focus_scroll_policy.dart';
import '../../../core/control/superfocus/interaction_manager.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/control/superfocus/focus_geometry.dart';
import '../../../core/control/superfocus/focus_report.dart';

class FloatingHighlightBox extends StatefulWidget {
  const FloatingHighlightBox({super.key});

  @override
  State<FloatingHighlightBox> createState() => _FloatingHighlightBoxState();
}

enum _TeleportState { idle, waiting, fadingIn }

class _FloatingHighlightBoxState extends State<FloatingHighlightBox>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Rect? _liveRect;
  Rect? _lastValidRect;
  BuildContext? _currentTrackingContext;
  bool _isTransitioning = false;
  Timer? _transitionTimer;
  _TeleportState __teleportState = _TeleportState.idle;
  
  _TeleportState get _teleportState => __teleportState;
  
  set _teleportState(_TeleportState value) {
    if (__teleportState != value) {
      // Debug: _teleportState mutation removed
      // Uncomment to trace: print(StackTrace.current);
      __teleportState = value;
    }
  }
  bool _isWaiting = false;
  double _dashPhase = 0.0;

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
    SuperFocusManager.instance.cursorWaitingNotifier.addListener(
      _handleWaitingUpdate,
    );
    SuperFocusManager.instance.intentionRoomId.addListener(
      _handleWaitingUpdate,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transitionTimer?.cancel();
    _idleTimer?.cancel();
    SuperFocusManager.instance.cursorReportNotifier.removeListener(
      _handleServiceUpdate,
    );
    SuperFocusManager.instance.cursorHiddenNotifier.removeListener(
      _handleServiceUpdate,
    );
    SuperFocusManager.instance.cursorWaitingNotifier.removeListener(
      _handleWaitingUpdate,
    );
    SuperFocusManager.instance.intentionRoomId.removeListener(
      _handleWaitingUpdate,
    );
    super.dispose();
  }

  void _handleWaitingUpdate() {
    if (mounted) {
      setState(() {
        _isWaiting = SuperFocusManager.instance.cursorWaitingNotifier.value ||
            SuperFocusManager.instance.intentionRoomId.value != null;
      });
    }
  }

  Timer? _idleTimer;

  void _handleServiceUpdate() {
    final report = SuperFocusManager.instance.cursorReportNotifier.value;
    if (report?.context != _currentTrackingContext) {
      _currentTrackingContext = report?.context;

      if (report?.transitionMode == FocusTransitionMode.teleport) {
        _teleportState = _TeleportState.waiting;
        SuperFocusManager.instance.state.cursorTeleportingNotifier.value = true;
        final delay =
            report?.teleportDelay ?? const Duration(milliseconds: 200);

        // Debug: Entering teleport waiting state removed

        // --- DIAGNOSTIC TIMER ---
        int ticks = 0;
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
          ticks++;
          if (ticks > (delay.inMilliseconds ~/ 100)) {
            timer.cancel();
            return;
          }
          // isVisible flag removed (unused in timer)
          // isTeleportVisible flag removed (unused in timer)
          // opacity calculation removed
          // Debug: Cursor tick removed
        });
        // ------------------------

        _transitionTimer?.cancel();
        _idleTimer?.cancel();
        _transitionTimer = Timer(delay, () {
          // Debug: Teleport waiting finished removed
          if (mounted) {
            setState(() => _teleportState = _TeleportState.fadingIn);

            // 渐显完成后恢复闲置状态
            _idleTimer = Timer(const Duration(milliseconds: 200), () {
              if (mounted) {
                setState(() => _teleportState = _TeleportState.idle);
                SuperFocusManager.instance.state.cursorTeleportingNotifier.value = false;
              }
            });
          }
        });
      } else {
        // Debug: Entering normal slide transition state removed
        SuperFocusManager.instance.state.cursorTeleportingNotifier.value = false;
        _isTransitioning = true;
        _transitionTimer?.cancel();
        _idleTimer?.cancel();
        _transitionTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _isTransitioning = false);
          }
        });
      }
    }

    if (mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    // 更新等待状态的虚线动画相位 (转圈)
    if (_isWaiting) {
      setState(() {
        _dashPhase = (elapsed.inMilliseconds % 1000) / 1000.0;
      });
    }

    // 瞬移模式的 waiting 阶段，冻结追踪旧位置
    if (_teleportState == _TeleportState.waiting) {
      return;
    }

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

    // ！！！核心魔法 2：空气墙钳制 (Visual Clamp) ！！！
    final viewport = RenderAbstractViewport.maybeOf(renderBox);
    if (viewport is RenderBox) {
      final viewportBox = viewport as RenderBox;
      final viewportTransform = viewportBox.getTransformTo(null);
      final viewportRect = MatrixUtils.transformRect(
        viewportTransform,
        Offset.zero & viewportBox.size,
      );

      // 从上下文中无依赖地读取滚动策略
      final policyWidget = FocusScrollPolicy.read(report.context!);
      final EdgeInsets insets =
          policyWidget?.boundary.asEdgeInsets ?? EdgeInsets.zero;

      // 将 policy 的 insets 转换为针对该视口的内缩
      final Rect safeRect = Rect.fromLTRB(
        viewportRect.left + insets.left,
        viewportRect.top + insets.top,
        viewportRect.right - insets.right,
        viewportRect.bottom - insets.bottom,
      );

      Axis? scrollAxis;
      if (viewport is RenderViewportBase) {
        scrollAxis = axisDirectionToAxis(viewport.axisDirection);
      }

      // 确保 clamp 的 max 永远大于等于 min，防止超大组件反向吞噬报错
      double maxLeft = math.max(
        safeRect.left,
        safeRect.right - targetRect.width,
      );
      double maxTop = math.max(
        safeRect.top,
        safeRect.bottom - targetRect.height,
      );

      // ！！！核心优化：只在能够滚动的轴上施加空气墙钳制！！！
      // 如果某轴不可滚动（比如垂直瀑布流的横向），钳制会导致游标脱离卡片物理位置
      double clampedLeft = targetRect.left;
      double clampedTop = targetRect.top;

      if (scrollAxis == null || scrollAxis == Axis.horizontal) {
        clampedLeft = targetRect.left.clamp(safeRect.left, maxLeft);
      }
      if (scrollAxis == null || scrollAxis == Axis.vertical) {
        clampedTop = targetRect.top.clamp(safeRect.top, maxTop);
      }

      targetRect = Rect.fromLTWH(
        clampedLeft,
        clampedTop,
        targetRect.width,
        targetRect.height,
      );
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

    final isTeleportVisible = _teleportState != _TeleportState.waiting;

    final opacity = (isVisible && isTeleportVisible) ? 1.0 : 0.0;
    final osDpr = View.of(context).devicePixelRatio;
    final visualScale = 1.0 / osDpr;
    final targetRect = _liveRect ?? _lastValidRect ?? Rect.zero;

    final duration = (_isTransitioning && _teleportState == _TeleportState.idle)
        ? const Duration(milliseconds: 300)
        : Duration.zero;

    final opacityDuration = _teleportState == _TeleportState.waiting
        ? Duration.zero
        : const Duration(milliseconds: 200);

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
                    duration: opacityDuration,
                    opacity: opacity,
                    child: CustomPaint(
                      painter: _FocusOutlinePainter(
                        geometry: report?.geometry,
                        color: material.colors.accent,
                        visualScale: visualScale,
                        glowRadius: material.focusGlowRadius,
                        glowOpacity: material.focusGlowOpacity,
                        isWaiting: _isWaiting,
                        dashPhase: _dashPhase,
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
    required this.isWaiting,
    required this.dashPhase,
  });

  final FocusGeometry? geometry;
  final Color color;
  final double visualScale;
  final double glowRadius;
  final double glowOpacity;
  final bool isWaiting;
  final double dashPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = this.geometry;
    if (geometry == null) return;

    final rect = Offset.zero & size;
    final outlinePath = geometry.buildOutlinePath(rect);

    Path renderPath;
    if (isWaiting) {
      // 提取虚线轮廓
      renderPath = Path();
      for (final metric in outlinePath.computeMetrics()) {
        final length = metric.length;
        final dashLength = 20.0 * visualScale;
        final gapLength = 20.0 * visualScale;
        final patternLength = dashLength + gapLength;
        // 旋转相位
        final startOffset = dashPhase * patternLength;

        double distance = -startOffset;
        while (distance < length) {
          final start = distance;
          final end = distance + dashLength;
          if (end > 0 && start < length) {
            final extractStart = math.max(0.0, start);
            final extractEnd = math.min(length, end);
            renderPath.addPath(
              metric.extractPath(extractStart, extractEnd),
              Offset.zero,
            );
          }
          distance += patternLength;
        }
      }
    } else {
      renderPath = outlinePath;
    }

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

    canvas.drawPath(renderPath, shadowPaint);
    canvas.drawPath(renderPath, linePaint);

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
        oldDelegate.glowOpacity != glowOpacity ||
        oldDelegate.isWaiting != isWaiting ||
        oldDelegate.dashPhase != dashPhase;
  }
}
