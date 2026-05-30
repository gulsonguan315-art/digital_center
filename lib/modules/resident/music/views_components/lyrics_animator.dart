import 'package:flutter/material.dart';

enum LyricAnimationType {
  /// 电影感淡入 + 轻微放大（适合碎片/情绪模式）
  fadeScale,
  
  /// 带有物理弹簧感的底部滑入（适合滚动模式）
  springSlideUp,
  
  /// 类似重力掉落并带有弹簧回弹（适合单行大字模式）
  elasticDrop,
}

/// 统一的歌词动效引擎包装器
/// 为所有歌词模式提供标准化的入场/出场动画
class LyricsAnimator extends StatefulWidget {
  final Widget child;
  final LyricAnimationType type;
  
  /// 传入的动画时长
  final Duration duration;
  
  /// 入场动画的延迟（用于实现错落入场）
  final Duration delay;

  const LyricsAnimator({
    super.key,
    required this.child,
    this.type = LyricAnimationType.fadeScale,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  });

  @override
  State<LyricsAnimator> createState() => _LyricsAnimatorState();
}

class _LyricsAnimatorState extends State<LyricsAnimator> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    // 使用真实的延迟，而不是拉长 AnimatedSwitcher 的总时长。
    // 拉长总时长会导致动画播放极度缓慢，从而引发 Windows 平台下致命的亚像素对齐闪烁（Jitter）。
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _show = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.duration,
      // 退出时使用更快的时间
      reverseDuration: widget.type == LyricAnimationType.elasticDrop 
          ? const Duration(milliseconds: 400) 
          : widget.duration,
      switchInCurve: _getInCurve(),
      switchOutCurve: _getOutCurve(),
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            ...previousChildren.map((w) => Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: w,
                  ),
                )),
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        switch (widget.type) {
          case LyricAnimationType.fadeScale:
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                // 从 0.85 放大到 1.0
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                child: child,
              ),
            );
            
          case LyricAnimationType.springSlideUp:
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                // 从下方 20% 位置弹簧滑入
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );

          case LyricAnimationType.elasticDrop:
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  // 提早结束透明度动画，让弹簧效果更清晰可见
                  curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
                ),
              ),
              child: SlideTransition(
                // 从上方 40% 的位置掉落
                position: Tween<Offset>(
                  begin: const Offset(0, -0.4),
                  end: Offset.zero,
                ).animate(animation),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
            );
        }
      },
      child: _show 
          ? widget.child 
          : Opacity(
              key: ValueKey('empty_${widget.key.hashCode}'),
              opacity: 0.0,
              child: widget.child,
            ),
    );
  }

  Curve _getInCurve() {
    switch (widget.type) {
      case LyricAnimationType.fadeScale:
        return Curves.easeOutBack; // 带有轻微回弹的拉伸
      case LyricAnimationType.springSlideUp:
        return Curves.elasticOut; // 强烈的弹簧震荡
      case LyricAnimationType.elasticDrop:
        return Curves.bounceOut; // 像皮球一样的物理掉落回弹
    }
  }

  Curve _getOutCurve() {
    switch (widget.type) {
      case LyricAnimationType.fadeScale:
        return Curves.easeInQuint;
      case LyricAnimationType.springSlideUp:
        return Curves.easeIn;
      case LyricAnimationType.elasticDrop:
        return Curves.easeInQuart;
    }
  }
}
