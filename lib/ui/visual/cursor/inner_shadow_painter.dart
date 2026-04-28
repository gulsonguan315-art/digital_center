import 'package:flutter/material.dart';

class InnerShadowPainter extends CustomPainter {
  final Color color;
  final Offset offset;
  final double blur;
  final double radius;

  InnerShadowPainter({
    required this.color,
    required this.offset,
    required this.blur,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;

    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 剪裁出按钮内部区域，只在这个范围内绘制阴影
    canvas.clipRRect(rrect);

    final Paint shadowPaint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    // 创建一个“带洞”的面具路径
    // 我们绘制这个面具，并让它产生位移。
    // 影子的部分会从边缘“渗漏”进那个洞（即按钮内部）
    final Path maskPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(size.width)) // 足够大的外部包围盒
      ..addRRect(rrect); // 挖去中间的按钮形状

    // 将面具按照反向偏移移动，模拟阴影投入。
    // 如果想要 CSS 的阴影位置是一致的，这里直接用 offset 即可。
    canvas.drawPath(maskPath.shift(offset), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant InnerShadowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.offset != offset ||
      oldDelegate.blur != blur ||
      oldDelegate.radius != radius;
}
