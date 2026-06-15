import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:superfocus/core/control/superfocus/scroll/focus_scroll_engine.dart';
import 'package:superfocus/core/control/superfocus/scroll/focus_scroll_policy.dart';
import 'package:superfocus/core/control/superfocus/scroll/focus_alignment.dart';
import '../../../log/log_api.dart';

class AutoScrollDispatcher {
  /// 确保节点在安全区内，否则触发带有“呼吸回弹”的滚动
  static void ensureVisible(BuildContext context, {FocusAlignment alignment = FocusAlignment.keepVisible}) {
    final RenderObject? object = context.findRenderObject();
    if (object == null || !object.attached || object is! RenderBox) return;

    RenderObject? targetObject = object;
    BuildContext? currentContext = context;
    ScrollableState? scrollable = Scrollable.maybeOf(currentContext);

    while (scrollable != null && targetObject != null) {
      // ！！！核心修复 1：用 maybeOf 精准捕获真正的视口，而不是 Scrollable 的包装对象 ！！！
      final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(targetObject);
      if (viewport == null) break;

      final ScrollPosition position = scrollable.position;
      
      // 获取原始元素在当前 Viewport 坐标系下的相对起始偏移量
      final double alignmentOffset = viewport.getOffsetToReveal(object, 0.0).offset;
      final double itemSize = position.axis == Axis.vertical ? object.size.height : object.size.width;
      final double viewportSize = position.viewportDimension;

      final double targetStart = alignmentOffset - position.pixels;
      final double targetEnd = targetStart + itemSize;

      // 获取安全区边界（使用最底层的 focus context 获取）
      final FocusScrollPolicy? policy = FocusScrollPolicy.read(context);
      final FocusScrollBoundary boundary = policy?.boundary ?? const FocusScrollBoundary(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0);
      
      final double paddingStart = position.axis == Axis.vertical ? boundary.top : boundary.left;
      final double paddingEnd = position.axis == Axis.vertical ? boundary.bottom : boundary.right;

      // 计算需要的滚动量
      final double delta = FocusScrollEngine.calculateDelta(
        targetStart: targetStart,
        targetEnd: targetEnd,
        viewportStart: 0.0,
        viewportEnd: viewportSize,
        paddingStart: paddingStart,
        paddingEnd: paddingEnd,
        currentPixels: position.pixels,
        alignment: alignment,
      );

      if (delta != 0.0) {
        final double targetPixels = (position.pixels + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );

        // 忽略极小的抖动
        if ((targetPixels - position.pixels).abs() >= 1.0) {
          Log.d(LogGroup.focus, '🌊 触发自动滚动 (Delta: $delta, Axis: ${position.axis})', subGroup: 'AutoScroll');

          // 移除越界回弹曲线，改用平滑减速的 easeOutQuart，避免焦点框出现飞过头再掉头的问题
          position.animateTo(
            targetPixels,
            duration: const Duration(milliseconds: 400), 
            curve: Curves.easeOutQuart,
          );
        }
      }

      // ！！！核心修复 2：冒泡遍历，让多层嵌套的 ScrollView 一层层网上滚 ！！！
      // 必须取 viewport.parent，否则下一次 maybeOf 会立刻找到自己，导致视口错乱！
      targetObject = viewport.parent;
      currentContext = scrollable.context;
      scrollable = Scrollable.maybeOf(currentContext);
    }
  }
}
