import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_colors.dart';

/// 纹理簇数据模型
class SilkCluster {
  final Offset baseStart;
  final Offset baseEnd;
  final Offset cp1;
  final Offset cp2;
  final List<SilkLine> lines;

  SilkCluster({
    required this.baseStart,
    required this.baseEnd,
    required this.cp1,
    required this.cp2,
    required this.lines,
  });
}

/// 每一根细丝的数据
class SilkLine {
  final Offset start;
  final Offset end;
  final Offset cp1;
  final Offset cp2;
  final double thickness;
  final double alpha;

  SilkLine({
    required this.start,
    required this.end,
    required this.cp1,
    required this.cp2,
    required this.thickness,
    required this.alpha,
  });
}

class SilkBackground extends StatefulWidget {
  final Color? color;
  final Widget? child;

  const SilkBackground({super.key, this.color, this.child});

  @override
  State<SilkBackground> createState() => _SilkBackgroundState();
}

class _SilkBackgroundState extends State<SilkBackground> {
  ui.Picture? _cachedPicture;
  Size? _lastSize;
  Color? _lastColor;

  @override
  void dispose() {
    _cachedPicture?.dispose();
    super.dispose();
  }

  void _generateArt(Size size, Color color) {
    if (_lastSize == size && _lastColor == color && _cachedPicture != null) {
      return;
    }

    _lastSize = size;
    _lastColor = color;
    _cachedPicture?.dispose();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & size);

    final random = math.Random();
    const clusterMin = 5;
    const clusterMax = 9;
    const linesPerClusterMax = 14;
    const clusterSpread = 200.0;

    final numClusters =
        clusterMin + random.nextInt(clusterMax - clusterMin + 1);
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.max(size.width, size.height) * 1.3;

    for (int i = 0; i < numClusters; i++) {
      final angleStart = random.nextDouble() * math.pi * 2;
      final angleEnd = angleStart + math.pi + (random.nextDouble() - 0.4);

      final baseStart = Offset(
        centerX + math.cos(angleStart) * radius,
        centerY + math.sin(angleStart) * radius,
      );
      final baseEnd = Offset(
        centerX + math.cos(angleEnd) * radius,
        centerY + math.sin(angleEnd) * radius,
      );

      final cp1 = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final cp2 = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );

      final numLines = 1 + random.nextInt(linesPerClusterMax);

      for (int l = 0; l < numLines; l++) {
        final start =
            baseStart +
            Offset(
              (random.nextDouble() - 0.5) * clusterSpread,
              (random.nextDouble() - 0.5) * clusterSpread,
            );
        final end =
            baseEnd +
            Offset(
              (random.nextDouble() - 0.5) * clusterSpread,
              (random.nextDouble() - 0.5) * clusterSpread,
            );
        final lCp1 =
            cp1 +
            Offset(
              (random.nextDouble() - 0.5) * clusterSpread * 1.5,
              (random.nextDouble() - 0.5) * clusterSpread * 1.5,
            );
        final lCp2 =
            cp2 +
            Offset(
              (random.nextDouble() - 0.5) * clusterSpread * 1.5,
              (random.nextDouble() - 0.5) * clusterSpread * 1.5,
            );

        final thickness = 0.4 + random.nextDouble() * 2.2;
        final lineAlpha = 0.04 + random.nextDouble() * 0.22;
        final finalAlpha = color.opacity * lineAlpha;

        final paint = Paint()
          ..color = color.withValues(alpha: finalAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round;

        if (thickness > 1.6 && finalAlpha > 0.01) {
          final shadowPaint = Paint()
            ..color = color.withValues(alpha: finalAlpha * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = thickness * 1.8
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

          _drawBezier(canvas, start, lCp1, lCp2, end, shadowPaint);
        }

        _drawBezier(canvas, start, lCp1, lCp2, end, paint);
      }
    }

    _cachedPicture = recorder.endRecording();
  }

  void _drawBezier(
    Canvas canvas,
    Offset start,
    Offset cp1,
    Offset cp2,
    Offset end,
    Paint paint,
  ) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;
    final silkColor = widget.color ?? themeColors.silk;

    return Stack(
      children: [
        // 1. 底层背景色
        Positioned.fill(child: Container(color: themeColors.backgroundCustom)),
        // 2. 丝织纹理层
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              if (size.width > 0 && size.height > 0) {
                _generateArt(size, silkColor);
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _lastSize = null; // Force refresh
                  });
                },
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: size,
                    painter: _SilkPicturePainter(picture: _cachedPicture),
                  ),
                ),
              );
            },
          ),
        ),
        // 3. 装饰元素
        Positioned(
          top: 100,
          left: -50,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColors.adormColor.withValues(alpha: 0.08),
            ),
          ),
        ),
        // 4. 内容槽位
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _SilkPicturePainter extends CustomPainter {
  final ui.Picture? picture;
  _SilkPicturePainter({this.picture});

  @override
  void paint(Canvas canvas, Size size) {
    if (picture != null) {
      canvas.drawPicture(picture!);
    }
  }

  @override
  bool shouldRepaint(_SilkPicturePainter oldDelegate) =>
      oldDelegate.picture != picture;
}
