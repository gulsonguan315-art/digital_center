import 'package:flutter/material.dart';
import '../layout/grid/grid_extensions.dart';

class StageHeroTransition extends StatelessWidget {
  final Widget child;
  final bool isVisible;
  final Rect? heroRect;

  const StageHeroTransition({
    super.key,
    required this.child,
    required this.isVisible,
    required this.heroRect,
  });

  @override
  Widget build(BuildContext context) {
    // 如果没有源坐标，直接回退为普通显示（虽然不该发生）
    if (heroRect == null) {
      return Offstage(offstage: !isVisible, child: child);
    }

    // 全屏 Rect（因为目前二楼已经处于独立的无 Padding 全屏层级）
    final fullScreenRect = Rect.fromLTWH(
      0,
      0,
      MediaQuery.sizeOf(context).width,
      MediaQuery.sizeOf(context).height,
    );

    // 因为父容器已经是全屏，全局坐标无需转换即为本地坐标
    final startRect = heroRect!;

    // 根据可见状态决定目标 Rect
    final targetRect = isVisible ? fullScreenRect : startRect;

    return TweenAnimationBuilder<Rect?>(
      tween: RectTween(begin: startRect, end: targetRect),
      duration: const Duration(milliseconds: 350),
      curve: isVisible ? Curves.easeInOutCubic : Curves.easeInCubic,
      builder: (context, rect, childWidget) {
        if (rect == null) return const SizedBox.shrink();

        // 动画完全结束且处于隐藏状态时，真正变为 SizedBox.shrink 避免渲染
        if (!isVisible && rect == startRect) {
          return const SizedBox.shrink();
        }

        // 计算动画进度用于文字渐显等内部特效 (反向计算进度)
        final progress =
            (rect.width - startRect.width) /
            (fullScreenRect.width - startRect.width + 0.1);

        return Positioned.fromRect(
          rect: rect,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              context.units(4) * (1 - progress.clamp(0.0, 1.0)),
            ),
            child: OverflowBox(
              minWidth: fullScreenRect.width,
              maxWidth: fullScreenRect.width,
              minHeight: fullScreenRect.height,
              maxHeight: fullScreenRect.height,
              alignment: Alignment.center,
              child: Transform.scale(
                scale: 0.9 + 0.1 * progress.clamp(0.0, 1.0),
                child: Material(
                  type: MaterialType.transparency,
                  child: childWidget,
                ),
              ),
            ),
          ),
        );
      },
      child: child, // 这里的 child 就是详情页
    );
  }
}
