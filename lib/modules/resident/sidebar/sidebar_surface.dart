import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
import 'sidebar_metrics.dart';

class SidebarSurface extends StatelessWidget {
  const SidebarSurface({
    super.key,
    required this.child,
    this.notchPath,
    this.radius,
    this.width,
    this.roundLeft = true,
  });

  final Widget child;
  final Path? notchPath;
  final double? radius;
  final double? width;
  final bool roundLeft;

  @override
  Widget build(BuildContext context) {
    // 1. 进饭店（核验身份）
    final material = context.useTheme();

    // 2. 定形状参数
    final double effectiveWidth = width ?? context.units(SidebarMetrics.widthU);
    final double effectiveRadius =
        radius ?? context.units(SidebarMetrics.surfaceRadiusU);

    // 3. 呼叫“自动上菜机”：
    // 把身份证（material）和盘子图纸（pathBuilder）交出去。
    // 这里不再有任何绘图代码，全部由 ThemePainter 在底层搞定。
    return ThemePainter(
      material: material,
      pathBuilder: (size) => _buildPath(size, effectiveWidth, effectiveRadius),
      child: child,
    );
  }

  /// 形状构建逻辑（组件的本分）
  Path _buildPath(Size size, double width, double radius) {
    if (size.height <= 0 || size.width <= 0) return Path();
    final drawWidth = (width == size.width) ? width : size.width;
    final safeRadius = radius.clamp(0.0, size.height / 2.0);

    final platePath = Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          0,
          0,
          drawWidth,
          size.height,
          topLeft: roundLeft ? Radius.circular(safeRadius) : Radius.zero,
          bottomLeft: roundLeft ? Radius.circular(safeRadius) : Radius.zero,
          topRight: Radius.circular(safeRadius),
          bottomRight: Radius.circular(safeRadius),
        ),
      );

    if (notchPath == null) return platePath;
    return Path.combine(PathOperation.difference, platePath, notchPath!);
  }
}
