import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
import '../../../core/control/superfocus/focus_api.dart'; // 这里引用是合理的，因为它是 UI 装饰逻辑
import 'sidebar_metrics.dart';

class SidebarSurface extends StatelessWidget {
  const SidebarSurface({
    super.key,
    required this.child,
    this.activeKey, // 接收当前激活项的 Key 以便实时追踪
    this.radius,
    this.width,
    this.roundLeft = true,
  });

  final Widget child;
  final GlobalKey? activeKey;
  final double? radius;
  final double? width;
  final bool roundLeft;

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final double effectiveWidth = width ?? context.units(SidebarMetrics.widthU);
    final double effectiveRadius = radius ?? context.units(SidebarMetrics.surfaceRadiusU);

    return ThemePainter(
      material: material,
      pathBuilder: (size) => _buildPath(context, size, effectiveWidth, effectiveRadius),
      child: child,
    );
  }

  Path _buildPath(BuildContext context, Size size, double width, double radius) {
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

    if (activeKey == null || activeKey!.currentContext == null) return platePath;

    final tileBox = activeKey!.currentContext!.findRenderObject() as RenderBox?;
    final surfaceBox = context.findRenderObject() as RenderBox?;
    if (tileBox == null || surfaceBox == null || !tileBox.hasSize || !surfaceBox.hasSize) return platePath;

    final localOffset = tileBox.localToGlobal(Offset.zero, ancestor: surfaceBox);

    // 在内部处理 Notch 的几何计算，实时根据当前画板宽度和动态相对位置调整
    final Rect dynamicActiveRect = Rect.fromLTRB(
      localOffset.dx, 
      localOffset.dy, 
      size.width, 
      localOffset.dy + tileBox.size.height
    );

    final notchPath = SidebarTileFocusGeometry(
      borderRadius: BorderRadius.circular(context.units(SidebarMetrics.tileRadiusU)),
      openRightness: 1.0,
      concaveRadius: context.units(SidebarMetrics.surfaceRadiusU),
    ).buildCutoutPath(dynamicActiveRect);

    if (notchPath == null) return platePath;
    return Path.combine(PathOperation.difference, platePath, notchPath);
  }
}
