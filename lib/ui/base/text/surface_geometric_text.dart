import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3, Quaternion;
import 'geometric_digits.dart';
import '../../../core/engine/theme/theme_api.dart';

class SurfaceGeometricText extends StatelessWidget {
  const SurfaceGeometricText(
    this.text, {
    super.key,
    this.size, 
    this.spacing = 0.15,
    this.padding = const EdgeInsets.all(16),
  });

  final String text;
  final double? size;
  final double spacing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final chrome = material.visual;
    final colors = material.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - padding.horizontal;
        final availableHeight = constraints.maxHeight - padding.vertical;

        const charWidth = 0.8;
        const charHeight = 1.0;
        final totalRelativeWidth = (text.length - 1) * (1 + spacing) + charWidth;

        final scaleW = availableWidth / totalRelativeWidth;
        final scaleH = availableHeight / charHeight;
        final finalSize = size ?? (scaleW < scaleH ? scaleW : scaleH);

        return Padding(
          padding: padding,
          child: Center(
            child: CustomPaint(
              size: Size(totalRelativeWidth * finalSize, charHeight * finalSize),
              painter: _GeometricTextPainter(
                text: text,
                size: finalSize,
                spacing: spacing,
                innerShadows: chrome.innerShadows,
                color: colors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GeometricTextPainter extends CustomPainter {
  _GeometricTextPainter({
    required this.text,
    required this.size,
    required this.spacing,
    required this.innerShadows,
    required this.color,
  });

  final String text;
  final double size;
  final double spacing;
  final List<BoxShadow> innerShadows;
  final Color color;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final fullPath = _buildCombinedPath();

    // 1. 底色
    canvas.drawPath(fullPath, Paint()..color = color.withValues(alpha: 0.1));

    // 2. 极简内阴影（反转位移实现左上阴影）
    if (innerShadows.isNotEmpty) {
      final shadow = innerShadows.first;
      canvas.save();
      canvas.clipPath(fullPath);
      canvas.translate(-shadow.offset.dx, -shadow.offset.dy); // 👈 反转实现左上
      canvas.drawPath(fullPath, Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius)
      );
      canvas.restore();
    }
  }

  Path _buildCombinedPath() {
    final combinedPath = Path();
    double currentX = 0;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      Path charPath;
      
      if (char == ':') {
        charPath = GeometricDigits.getColonPath();
      } else {
        final digit = int.tryParse(char);
        if (digit != null) {
          charPath = GeometricDigits.getPath(digit);
        } else {
          continue;
        }
      }

      final matrix = Matrix4.compose(
        Vector3(currentX, 0.0, 0.0),
        Quaternion.identity(),
        Vector3(size, size, 1.0),
      );
      
      combinedPath.addPath(charPath, Offset.zero, matrix4: matrix.storage);
      currentX += size * (1 + spacing);
    }
    
    return combinedPath;
  }

  @override
  bool shouldRepaint(_GeometricTextPainter oldDelegate) =>
      text != oldDelegate.text ||
      size != oldDelegate.size ||
      innerShadows != oldDelegate.innerShadows;
}
