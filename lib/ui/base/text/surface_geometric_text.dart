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

        // 彻底动态化：直接读取几何引擎的物理参数
        const charWidth = GeometricDigits.w;
        const charHeight = GeometricDigits.h;
        
        final totalRelativeWidth = (text.length - 1) * (charWidth * (1 + spacing)) + charWidth;

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
                color: colors.foreground,
                ghostColor: colors.foregroundDisabled,
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
    required this.ghostColor,
  });

  final String text;
  final double size;
  final double spacing;
  final List<BoxShadow> innerShadows;
  final Color color;
  final Color ghostColor;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // 1. 构建路径
    final ghostPath = _buildGhostPath();
    final fullPath = _buildCombinedPath();

    // 2. 绘制背景底影
    canvas.drawPath(ghostPath, Paint()..color = ghostColor);

    // 3. 绘制主色调 (实际数字)
    canvas.drawPath(fullPath, Paint()..color = color);

    // 4. 真正的内阴影实现 (反向路径叠加法)
    if (innerShadows.isNotEmpty) {
      for (final shadow in innerShadows) {
        canvas.save();
        canvas.clipPath(fullPath);
        
        // 创建一个反向路径：一个巨大矩形减去当前数字路径
        final invertedPath = Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Rect.fromLTWH(-canvasSize.width, -canvasSize.height, canvasSize.width * 3, canvasSize.height * 3))
          ..addPath(fullPath, shadow.offset); // 👈 偏移阴影

        canvas.drawPath(invertedPath, Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius)
        );
        
        canvas.restore();
      }
    }
  }

  /// 构建整排的底影“8”路径
  Path _buildGhostPath() {
    final ghostPath = Path();
    double currentX = 0;
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == ':') {
        currentX += size * (1 + spacing);
        continue;
      }
      final matrix = Matrix4.compose(
        Vector3(currentX, 0.0, 0.0),
        Quaternion.identity(),
        Vector3(size, size, 1.0),
      );
      ghostPath.addPath(GeometricDigits.getBackgroundPath(), Offset.zero, matrix4: matrix.storage);
      currentX += size * GeometricDigits.w * (1 + spacing);
    }
    return ghostPath;
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
          currentX += size * (1 + spacing);
          continue;
        }
      }

      final matrix = Matrix4.compose(
        Vector3(currentX, 0.0, 0.0),
        Quaternion.identity(),
        Vector3(size, size, 1.0),
      );
      
      combinedPath.addPath(charPath, Offset.zero, matrix4: matrix.storage);
      currentX += size * GeometricDigits.w * (1 + spacing);
    }
    
    return combinedPath;
  }

  @override
  bool shouldRepaint(_GeometricTextPainter oldDelegate) =>
      text != oldDelegate.text ||
      size != oldDelegate.size ||
      innerShadows != oldDelegate.innerShadows;
}
