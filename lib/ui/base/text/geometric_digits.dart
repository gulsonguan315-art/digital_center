import 'package:flutter/material.dart';

/// 7段式几何数字路径生成器 - 拼图斜切版 (真正解决缺角问题)
class GeometricDigits {
  static const double t = 0.2; // 笔画厚度
  static const double w = 0.8; // 逻辑宽度
  static const double h = 1.5; // 逻辑高度
  static const double s = 0.05; // 物理缝隙

  static Path getPath(int digit) {
    final segments = _getSegmentsForDigit(digit);
    return _buildPathFromSegments(segments);
  }

  static Path getBackgroundPath() {
    return _buildPathFromSegments([true, true, true, true, true, true, true]);
  }

  static List<bool> _getSegmentsForDigit(int digit) {
    switch (digit) {
      case 0:
        return [true, true, true, true, true, true, false];
      case 1:
        return [false, true, true, false, false, false, false];
      case 2:
        return [true, true, false, true, true, false, true];
      case 3:
        return [true, true, true, true, false, false, true];
      case 4:
        return [false, true, true, false, false, true, true];
      case 5:
        return [true, false, true, true, false, true, true];
      case 6:
        return [true, false, true, true, true, true, true];
      case 7:
        return [true, true, true, false, false, false, false];
      case 8:
        return [true, true, true, true, true, true, true];
      case 9:
        return [true, true, true, true, false, true, true];
      default:
        return [false, false, false, false, false, false, false];
    }
  }

  static Path _buildPathFromSegments(List<bool> active) {
    final path = Path();

    // A (Top) - 梯形
    if (active[0]) {
      path.addPath(
        _polygon([
          Offset(s, 0),
          Offset(w - s, 0),
          Offset(w - t - s, t),
          Offset(t + s, t),
        ]),
        Offset.zero,
      );
    }
    // B (Right Top) - 梯形
    if (active[1]) {
      path.addPath(
        _polygon([
          Offset(w, s),
          Offset(w, h / 2 - s),
          Offset(w - t, h / 2 - t / 2 - s),
          Offset(w - t, t + s),
        ]),
        Offset.zero,
      );
    }
    // C (Right Bot) - 梯形
    if (active[2]) {
      path.addPath(
        _polygon([
          Offset(w, h / 2 + s),
          Offset(w, h - s),
          Offset(w - t, h - t - s),
          Offset(w - t, h / 2 + t / 2 + s),
        ]),
        Offset.zero,
      );
    }
    // D (Bottom) - 梯形
    if (active[3]) {
      path.addPath(
        _polygon([
          Offset(s, h),
          Offset(w - s, h),
          Offset(w - t - s, h - t),
          Offset(t + s, h - t),
        ]),
        Offset.zero,
      );
    }
    // E (Left Bot) - 梯形
    if (active[4]) {
      path.addPath(
        _polygon([
          Offset(0, h / 2 + s),
          Offset(0, h - s),
          Offset(t, h - t - s),
          Offset(t, h / 2 + t / 2 + s),
        ]),
        Offset.zero,
      );
    }
    // F (Left Top) - 梯形
    if (active[5]) {
      path.addPath(
        _polygon([
          Offset(0, s),
          Offset(0, h / 2 - s),
          Offset(t, h / 2 - t / 2 - s),
          Offset(t, t + s),
        ]),
        Offset.zero,
      );
    }
    // G (Middle) - 六角形 (深度嵌入，解决横线过短问题)
    if (active[6]) {
      path.addPath(
        _polygon([
          Offset(s, h / 2), // 左尖端 (插入凹槽)
          Offset(t + s, h / 2 - t / 2), // 左上肩 (对齐竖线内边缘)
          Offset(w - t - s, h / 2 - t / 2), // 右上肩
          Offset(w - s, h / 2), // 右尖端 (插入凹槽)
          Offset(w - t - s, h / 2 + t / 2), // 右下肩
          Offset(t + s, h / 2 + t / 2), // 左下肩
        ]),
        Offset.zero,
      );
    }

    return path;
  }

  static Path _polygon(List<Offset> points) {
    final p = Path();
    p.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      p.lineTo(points[i].dx, points[i].dy);
    }
    p.close();
    return p;
  }

  static Path getColonPath() {
    return Path()
      ..addOval(Rect.fromLTWH(w / 2 - t / 2, h * 0.35 - t / 2, t, t))
      ..addOval(Rect.fromLTWH(w / 2 - t / 2, h * 0.65 - t / 2, t, t));
  }
}
