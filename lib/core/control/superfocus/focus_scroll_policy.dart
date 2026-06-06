import 'package:flutter/widgets.dart';

/// 定义滚动边界安全区，作用类似 EdgeInsets
class FocusScrollBoundary {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const FocusScrollBoundary({
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
  });

  /// 转换为 EdgeInsets
  EdgeInsets get asEdgeInsets => EdgeInsets.fromLTRB(left, top, right, bottom);

  factory FocusScrollBoundary.all(double value) {
    return FocusScrollBoundary(
      left: value,
      top: value,
      right: value,
      bottom: value,
    );
  }

  factory FocusScrollBoundary.fromEdgeInsets(EdgeInsets insets) {
    return FocusScrollBoundary(
      left: insets.left,
      top: insets.top,
      right: insets.right,
      bottom: insets.bottom,
    );
  }
}

/// 允许页面声明自身的焦点滚动安全区边界
class FocusScrollPolicy extends InheritedWidget {
  final FocusScrollBoundary boundary;

  const FocusScrollPolicy({
    super.key,
    required this.boundary,
    required super.child,
  });

  /// 获取作用域内的策略 (带有依赖绑定)
  static FocusScrollPolicy? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FocusScrollPolicy>();
  }

  /// 无依赖读取作用域内的策略（专门用于 Ticker 等不需要重建的回调场景）
  static FocusScrollPolicy? read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<FocusScrollPolicy>();
  }

  @override
  bool updateShouldNotify(FocusScrollPolicy oldWidget) {
    return boundary.left != oldWidget.boundary.left ||
        boundary.top != oldWidget.boundary.top ||
        boundary.right != oldWidget.boundary.right ||
        boundary.bottom != oldWidget.boundary.bottom;
  }
}
