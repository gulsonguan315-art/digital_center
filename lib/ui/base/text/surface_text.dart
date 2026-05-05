import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';

class SurfaceText extends StatelessWidget {
  const SurfaceText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final chrome = material.visual;
    final colors = material.colors;

    final baseStyle = (style ?? const TextStyle()).copyWith(
      decoration: TextDecoration.none,
    );

    if (chrome.innerShadows.isEmpty) {
      return Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: baseStyle.copyWith(color: baseStyle.color ?? colors.textPrimary),
      );
    }

    return CustomPaint(
      painter: _SurfaceTextPainter(
        text: text,
        style: baseStyle,
        shadow: chrome.innerShadows.first,
        baseColor: colors.textPrimary.withValues(alpha: 0.1),
      ),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: baseStyle.copyWith(color: Colors.transparent),
      ),
    );
  }
}

class _SurfaceTextPainter extends CustomPainter {
  _SurfaceTextPainter({
    required this.text,
    required this.style,
    required this.shadow,
    required this.baseColor,
  });

  final String text;
  final TextStyle style;
  final BoxShadow shadow;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: baseColor)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width);

    final pos = Offset(
      (size.width - tp.width) / 2,
      (size.height - tp.height) / 2,
    );

    // 1. 底板
    tp.paint(canvas, pos);

    // 2. 极简内阴影
    canvas.saveLayer(Offset.zero & size, Paint());
    
    // 遮罩
    tp.text = TextSpan(text: text, style: style.copyWith(color: Colors.white));
    tp.layout(maxWidth: size.width);
    tp.paint(canvas, pos);

    final shadowPaint = Paint()
      ..color = shadow.color
      ..blendMode = BlendMode.srcIn
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

    // 👈 反转位移，确保正向 Offset(2, 2) 产生左上方阴影
    canvas.translate(-shadow.offset.dx, -shadow.offset.dy);
    tp.text = TextSpan(text: text, style: style.copyWith(foreground: shadowPaint));
    tp.layout(maxWidth: size.width);
    tp.paint(canvas, pos);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SurfaceTextPainter oldDelegate) =>
      text != oldDelegate.text || style != oldDelegate.style;
}
