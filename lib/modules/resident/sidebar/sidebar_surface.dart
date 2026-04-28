import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_colors.dart';
import '../../../core/engine/theme/theme_visuals.dart';
import 'sidebar_metrics.dart';

class SidebarSurface extends StatelessWidget {
  const SidebarSurface({super.key, required this.child, this.notchPath});

  final Widget child;
  final Path? notchPath;

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;
    final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;

    return CustomPaint(
      painter: SidebarNotchPainter(
        surfaceColor: themeColors.sidebarMain,
        surfaceEffect: themeVisuals.sidebar.surfaceEffect,
        notchPath: notchPath,
      ),
      child: child,
    );
  }
}

class SidebarNotchPainter extends CustomPainter {
  SidebarNotchPainter({
    required this.surfaceColor,
    required this.surfaceEffect,
    required this.notchPath,
  });

  final Color surfaceColor;
  final SidebarSurfaceEffect surfaceEffect;
  final Path? notchPath;

  @override
  void paint(Canvas canvas, Size size) {
    final platePath = _getPlatePath(size);
    final finalPath = _getFinalPath(platePath);

    _paintSurfaceEffect(canvas, finalPath);

    final fillPaint = Paint()..color = surfaceColor;
    canvas.drawPath(finalPath, fillPaint);

    _paintSurfaceOverlay(canvas, finalPath);
  }

  void _paintSurfaceEffect(Canvas canvas, Path path) {
    switch (surfaceEffect) {
      case NoSidebarSurfaceEffect():
        return;
      case NeumorphSidebarSurfaceEffect effect:
        final keyShadowPaint = Paint()
          ..color = effect.keyShadowColor
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            effect.keyShadowBlur,
          );

        final ambientShadowPaint = Paint()
          ..color = effect.ambientShadowColor
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            effect.ambientShadowBlur,
          );

        canvas.save();
        canvas.translate(effect.keyShadowOffset.dx, effect.keyShadowOffset.dy);
        canvas.drawPath(path, keyShadowPaint);
        canvas.restore();

        canvas.save();
        canvas.translate(
          effect.ambientShadowOffset.dx,
          effect.ambientShadowOffset.dy,
        );
        canvas.drawPath(path, ambientShadowPaint);
        canvas.restore();
    }
  }

  void _paintSurfaceOverlay(Canvas canvas, Path path) {
    switch (surfaceEffect) {
      case NoSidebarSurfaceEffect():
        return;
      case NeumorphSidebarSurfaceEffect effect:
        if (effect.borderWidth <= 0) return;
        final rimPaint = Paint()
          ..color = effect.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = effect.borderWidth;
        canvas.drawPath(path, rimPaint);
    }
  }

  Path _getPlatePath(Size size) {
    final r = SidebarMetrics.surfaceRadius;
    return Path()..addRRect(
      RRect.fromLTRBAndCorners(
        0,
        0,
        SidebarMetrics.width,
        size.height,
        topRight: Radius.circular(r),
        bottomRight: Radius.circular(r),
      ),
    );
  }

  Path _getFinalPath(Path platePath) {
    if (notchPath == null) {
      return platePath;
    }
    return Path.combine(PathOperation.difference, platePath, notchPath!);
  }

  @override
  bool shouldRepaint(SidebarNotchPainter oldDelegate) {
    return oldDelegate.notchPath != notchPath ||
        oldDelegate.surfaceEffect != surfaceEffect ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}
