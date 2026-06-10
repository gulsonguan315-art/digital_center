import 'package:flutter/material.dart';
import '../engine/theme/theme_api.dart';
import '../layout/grid/grid_extensions.dart';
import 'stage_manager.dart';
import 'stage_metrics.dart';

/// 📂 舞台房间入场过渡转场组件
/// 当房间被激活时，播放从侧边栏下方（左侧）向右滑动出来的入场动画。
/// 返回时，整个画面向左移动滑回侧边栏下方消失。
/// 在动画播放期间，通过 [StageManager] 临时锁定焦点输入系统，防止游标抖动和用户误输入。
class StageRoomTransition extends StatefulWidget {
  final Widget child;
  final bool isVisible;

  const StageRoomTransition({
    super.key,
    required this.child,
    required this.isVisible,
  });

  @override
  State<StageRoomTransition> createState() => _StageRoomTransitionState();
}

class _StageRoomTransitionState extends State<StageRoomTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isOffstage = true;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // 进场：淡入 (0 -> 1)，退场：淡出 (1 -> 0)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // 整个画面从侧边栏下方（左侧）完全滑出到右侧 normal 位置
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _isOffstage = !widget.isVisible;

    if (widget.isVisible) {
      _startTransition();
    }
  }

  @override
  void didUpdateWidget(StageRoomTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        setState(() {
          _isOffstage = false;
        });
        _startTransition();
      } else {
        _startExitTransition();
      }
    }
  }

  void _startTransition() {
    _isAnimating = true;
    StageManager.instance.isTransitioning.value = true;
    _controller.forward().then((_) {
      _stopTransitionIfNeeded();
    });
  }

  void _startExitTransition() {
    _isAnimating = true;
    StageManager.instance.isTransitioning.value = true;
    _controller.reverse().then((_) {
      _stopTransitionIfNeeded();
      if (mounted && !widget.isVisible) {
        setState(() {
          _isOffstage = true;
        });
      }
    });
  }

  void _stopTransitionIfNeeded() {
    if (_isAnimating) {
      _isAnimating = false;
      // 在下一帧微调以确保生命周期完全契合
      WidgetsBinding.instance.addPostFrameCallback((_) {
        StageManager.instance.isTransitioning.value = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppTheme>()!;
    return Offstage(
      offstage: _isOffstage,
      child: TickerMode(
        enabled: !_isOffstage,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                context.units(StageMetrics.borderRadiusU),
              ),
              clipBehavior: Clip.none, // 🌟 允许卡片外部阴影/高光自然向外延伸，防止在边缘处被生硬切边
              child: Material(
                color: theme.colors.stageBackground,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
