import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme_layers.dart';

/// 【自动上菜机】：根据身份和形状，自动应用视觉特效
class ThemePainter extends StatelessWidget {
  const ThemePainter({
    super.key,
    required this.material,
    required this.pathBuilder,
    required this.child,
  });

  /// 身份证（包含菜单信息）
  final ResolvedThemeMaterial material;

  /// 盘子图纸（决定形状）
  final Path Function(Size size) pathBuilder;

  /// 客人（承载的内容）
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final chrome = material.visual;
    final fillColor = material.colors.surface;

    // 1. 基础图层 Stack
    Widget result = Stack(
      fit: StackFit.loose,
      clipBehavior: Clip.none,
      children: [
        // A. 绘制背景层 (包括底色、内阴影、高光)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SurfaceInternalPainter(
                chrome: chrome,
                fillColor: fillColor,
                pathBuilder: pathBuilder,
              ),
            ),
          ),
        ),
        
        // B. 放置内容
        child,
      ],
    );

    // 2. 处理背景模糊 (Glass 风格的核心)
    if (chrome.surfaceBlur > 0) {
      result = ClipPath(
        clipper: _PathClipper(pathBuilder),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: chrome.surfaceBlur,
            sigmaY: chrome.surfaceBlur,
          ),
          child: result,
        ),
      );
    }

    // 3. 处理外阴影 (Neumorph 风格的核心)
    if (chrome.outerShadows.isNotEmpty) {
      result = Stack(
        fit: StackFit.loose,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SurfaceOuterShadowPainter(
                  shadows: chrome.outerShadows,
                  pathBuilder: pathBuilder,
                ),
              ),
            ),
          ),
          result,
        ],
      );
    }

    return result;
  }
}

/// 内部绘制器：负责底色、内阴影、高光、边框
class _SurfaceInternalPainter extends CustomPainter {
  const _SurfaceInternalPainter({
    required this.chrome,
    required this.fillColor,
    required this.pathBuilder,
  });

  final SurfaceChrome chrome;
  final Color fillColor;
  final Path Function(Size size) pathBuilder;

  @override
  void paint(Canvas canvas, Size size) {
    final path = pathBuilder(size);
    final rect = Offset.zero & size;
    
    // 1. 画底色 (处理透明度)
    final paintFill = Paint()
      ..color = (chrome.surfaceOpacity < 1.0)
          ? fillColor.withValues(alpha: chrome.surfaceOpacity)
          : fillColor;
    canvas.drawPath(path, paintFill);

    // 2. 画内阴影 (Neumorph 凹陷效果)
    // 这里顺便修复 0 模糊不可见的问题
    for (final shadow in chrome.innerShadows) {
      canvas.save();
      canvas.clipPath(path);

      // 核心修复：底板纸（Spread）必须比偏移量大，否则挪动时会露出缝隙导致阴影消失
      final double offsetMag = shadow.offset.distance;
      final double spread = shadow.blurRadius == 0 
          ? (offsetMag + 1.0) 
          : (shadow.blurRadius * 2 + offsetMag);
      final shadowPath = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(spread))
        ..addPath(path, Offset.zero);

      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = shadow.color
          ..maskFilter = shadow.blurRadius > 0
              ? MaskFilter.blur(BlurStyle.normal, shadow.blurRadius)
              : null,
      );
      canvas.restore();
    }

    // 3. 画内高光 (如果有)
    if (chrome.innerHighlightColor != null && chrome.innerHighlightWidth > 0) {
      final paintHighlight = Paint()
        ..color = chrome.innerHighlightColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = chrome.innerHighlightWidth
        ..maskFilter = chrome.innerHighlightBlur > 0
            ? MaskFilter.blur(BlurStyle.normal, chrome.innerHighlightBlur)
            : null;
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(path, paintHighlight);
      canvas.restore();
    }

    // 4. 画边框
    if (chrome.borderWidth > 0 && chrome.borderColor != null) {
      final paintBorder = Paint()
        ..color = chrome.borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = chrome.borderWidth * 2 // 配合裁剪实现内描边
        ..maskFilter = chrome.borderBlur > 0
            ? MaskFilter.blur(BlurStyle.normal, chrome.borderBlur)
            : null;
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(path, paintBorder);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SurfaceInternalPainter old) => old.chrome != chrome || old.fillColor != fillColor;
}

/// 外部阴影绘制器
class _SurfaceOuterShadowPainter extends CustomPainter {
  const _SurfaceOuterShadowPainter({
    required this.shadows,
    required this.pathBuilder,
  });

  final List<BoxShadow> shadows;
  final Path Function(Size size) pathBuilder;

  @override
  void paint(Canvas canvas, Size size) {
    final path = pathBuilder(size);

    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = shadow.blurRadius > 0
            ? MaskFilter.blur(BlurStyle.normal, shadow.blurRadius)
            : null;
      
      canvas.save();
      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SurfaceOuterShadowPainter old) => old.shadows != shadows;
}

/// 通用裁剪器
class _PathClipper extends CustomClipper<Path> {
  _PathClipper(this.pathBuilder);
  final Path Function(Size size) pathBuilder;
  @override
  Path getClip(Size size) => pathBuilder(size);
  @override
  bool shouldReclip(_PathClipper old) => true;
}
