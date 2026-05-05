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
    this.width, // 👈
  });

  final Widget child;
  final Path? notchPath;
  final double? radius;
  final double? width; // 👈 增加可选宽度

  @override
  Widget build(BuildContext context) {
    // 1. 自动识别：内部已自动根据 Identity 解析出结果
    final material = context.useTheme();
    final chrome = material.visual;

    // 2. 动态计算：如果是侧边栏，用全宽；如果是局部容器，用传进来的宽度或跟随容器
    final double effectiveWidth = width ?? context.units(SidebarMetrics.widthU);
    final double effectiveRadius = radius ?? context.units(SidebarMetrics.surfaceRadiusU);

    final Color fillColor = (chrome.surfaceOpacity < 1.0)
        ? material.colors.surface.withValues(alpha: chrome.surfaceOpacity)
        : material.colors.surface;

    Widget content = Stack(
      fit: StackFit.loose, // 👈 改为宽松模式，避免在 Column 中无限膨胀
      clipBehavior: Clip.none,
      children: [
        if (chrome.outerShadows.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SidebarShadowPainter(
                  notchPath: notchPath,
                  shadows: chrome.outerShadows,
                  width: effectiveWidth, // 👈 使用有效宽度
                  radius: effectiveRadius,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SidebarSurfacePainter(
                notchPath: notchPath,
                fillColor: fillColor,
                borderColor: chrome.borderColor ?? Colors.transparent,
                borderWidth: chrome.borderWidth,
                borderBlur: chrome.borderBlur,
                innerHighlightColor: chrome.innerHighlightColor,
                innerHighlightWidth: chrome.innerHighlightWidth,
                innerHighlightBlur: chrome.innerHighlightBlur,
                innerShadows: chrome.innerShadows, 
                width: effectiveWidth, // 👈 使用有效宽度
                radius: effectiveRadius,
              ),
            ),
          ),
        ),
        child,
      ],
    );

    if (chrome.surfaceBlur > 0) {
      content = ClipPath(
        clipper: _SidebarSurfaceClipper(
          notchPath: notchPath,
          radius: effectiveRadius,
          width: effectiveWidth, // 👈 使用有效宽度
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: chrome.surfaceBlur,
            sigmaY: chrome.surfaceBlur,
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}

class _SidebarSurfaceClipper extends CustomClipper<Path> {
  const _SidebarSurfaceClipper({
    required this.notchPath,
    required this.radius,
    required this.width, // 👈 必须传进来，不能在 getClip 里猜
  });

  final Path? notchPath;
  final double radius;
  final double width;

  @override
  Path getClip(Size size) {
    return _SidebarSurfacePainter(
      notchPath: notchPath,
      fillColor: Colors.transparent,
      borderColor: Colors.transparent,
      width: width, // 👈 使用确定的物理宽度
      radius: radius,
    ).buildPath(size);
  }

  @override
  bool shouldReclip(_SidebarSurfaceClipper oldClipper) {
    return oldClipper.notchPath != notchPath || 
           oldClipper.radius != radius ||
           oldClipper.width != width;
  }
}

class _SidebarSurfacePainter extends CustomPainter {
  const _SidebarSurfacePainter({
    required this.notchPath,
    required this.fillColor,
    required this.borderColor,
    this.borderWidth = 0,
    this.borderBlur = 0,
    this.innerHighlightColor,
    this.innerHighlightWidth = 0,
    this.innerHighlightBlur = 0,
    this.innerShadows = const [], // 👈 增加内阴影参数
    required this.width,
    required this.radius,
  });

  final Path? notchPath;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double borderBlur;
  final Color? innerHighlightColor;
  final double innerHighlightWidth;
  final double innerHighlightBlur;
  final List<BoxShadow> innerShadows;
  final double width;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPath(size);
    final rect = Offset.zero & size;
    final fillPaint = Paint()..color = fillColor;

    canvas.drawPath(path, fillPaint);

    // --- 补全：内阴影绘制逻辑 ---
    if (innerShadows.isNotEmpty) {
      final shadow = innerShadows.first;
      canvas.save();
      canvas.clipPath(path);

      final shadowPath = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(shadow.blurRadius * 2))
        ..addPath(path, Offset.zero);

      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius),
      );
      canvas.restore();
    }

    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            borderWidth *
            2 // 双倍线宽，配合裁剪实现 100% 内侧描边
        ..maskFilter = borderBlur > 0
            ? MaskFilter.blur(BlurStyle.normal, borderBlur)
            : null;
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(path, borderPaint);
      canvas.restore();
    }

    if (innerHighlightColor != null && innerHighlightWidth > 0) {
      final innerHighlightPaint = Paint()
        ..color = innerHighlightColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerHighlightWidth
        ..maskFilter = innerHighlightBlur > 0
            ? MaskFilter.blur(BlurStyle.normal, innerHighlightBlur)
            : null;
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(path, innerHighlightPaint);
      canvas.restore();
    }
  }

  Path buildPath(Size size) {
    // 1. 安全加固：宽度应优先跟随布局，高度为 0 时直接返回空路径防止崩溃
    if (size.height <= 0 || size.width <= 0) return Path();

    // 2. 动态适配：如果是局部容器（如 Logo 区），信任布局给的 width
    final drawWidth = (width == size.width) ? width : size.width;
    
    // 3. 圆角极限保护：圆角不能超过高度的一半
    final safeRadius = radius.clamp(0.0, size.height / 2.0);

    final platePath = Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          0,
          0,
          drawWidth,
          size.height,
          topRight: Radius.circular(safeRadius),
          bottomRight: Radius.circular(safeRadius),
        ),
      );

    if (notchPath == null) {
      return platePath;
    }

    return Path.combine(PathOperation.difference, platePath, notchPath!);
  }

  @override
  bool shouldRepaint(_SidebarSurfacePainter oldDelegate) {
    return oldDelegate.notchPath != notchPath ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderBlur != borderBlur ||
        oldDelegate.innerHighlightColor != innerHighlightColor ||
        oldDelegate.innerHighlightWidth != innerHighlightWidth ||
        oldDelegate.innerHighlightBlur != innerHighlightBlur ||
        oldDelegate.innerShadows != innerShadows || // 👈 增加重绘判断
        oldDelegate.width != width ||
        oldDelegate.radius != radius;
  }
}

class _SidebarShadowPainter extends CustomPainter {
  const _SidebarShadowPainter({
    required this.notchPath,
    required this.shadows,
    required this.width,
    required this.radius,
  });

  final Path? notchPath;
  final List<BoxShadow> shadows;
  final double width;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final finalPath = _SidebarSurfacePainter(
      notchPath: notchPath,
      fillColor: Colors.transparent,
      borderColor: Colors.transparent,
      width: width,
      radius: radius,
    ).buildPath(size);

    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = shadow.blurRadius > 0
            ? MaskFilter.blur(BlurStyle.normal, shadow.blurRadius)
            : null;
      canvas.save();
      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.drawPath(finalPath, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SidebarShadowPainter oldDelegate) {
    return oldDelegate.notchPath != notchPath ||
        oldDelegate.shadows != shadows ||
        oldDelegate.width != width ||
        oldDelegate.radius != radius;
  }
}
