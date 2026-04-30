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
    final chrome = themeVisuals.panelSurface.chrome(
      context: context,
      isFocused: false,
      fillColor: themeColors.sidebarMain,
    );
    final borderRadius = const BorderRadius.only(
      topRight: Radius.circular(SidebarMetrics.surfaceRadius),
      bottomRight: Radius.circular(SidebarMetrics.surfaceRadius),
    );

    if (chrome == null) {
      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipPath(
              clipper: _SidebarSurfaceClipper(notchPath: notchPath),
              child: themeVisuals.panelSurface.apply(
                context,
                const SizedBox.expand(),
                isFocused: false,
                borderRadius: borderRadius,
                fillColor: themeColors.sidebarMain,
              ),
            ),
          ),
          child,
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (chrome.outerShadows.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SidebarShadowPainter(
                  notchPath: notchPath,
                  shadows: chrome.outerShadows,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SidebarSurfacePainter(
                notchPath: notchPath,
                fillColor: themeColors.sidebarMain,
                borderColor: chrome.borderColor ?? Colors.transparent,
                borderWidth: chrome.borderWidth,
                borderBlur: chrome.borderBlur,
                innerHighlightColor: chrome.innerHighlightColor,
                innerHighlightWidth: chrome.innerHighlightWidth,
                innerHighlightBlur: chrome.innerHighlightBlur,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _SidebarSurfaceClipper extends CustomClipper<Path> {
  const _SidebarSurfaceClipper({required this.notchPath});

  final Path? notchPath;

  @override
  Path getClip(Size size) {
    return _SidebarSurfacePainter(
      notchPath: notchPath,
      fillColor: Colors.transparent,
      borderColor: Colors.transparent,
    ).buildPath(size);
  }

  @override
  bool shouldReclip(_SidebarSurfaceClipper oldClipper) {
    return oldClipper.notchPath != notchPath;
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
  });

  final Path? notchPath;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double borderBlur;
  final Color? innerHighlightColor;
  final double innerHighlightWidth;
  final double innerHighlightBlur;

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPath(size);
    final fillPaint = Paint()..color = fillColor;

    canvas.drawPath(path, fillPaint);

    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
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
    final platePath = Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          0,
          0,
          SidebarMetrics.width,
          size.height,
          topRight: const Radius.circular(SidebarMetrics.surfaceRadius),
          bottomRight: const Radius.circular(SidebarMetrics.surfaceRadius),
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
        oldDelegate.innerHighlightBlur != innerHighlightBlur;
  }
}

class _SidebarShadowPainter extends CustomPainter {
  const _SidebarShadowPainter({required this.notchPath, required this.shadows});

  final Path? notchPath;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    final finalPath = _SidebarSurfacePainter(
      notchPath: notchPath,
      fillColor: Colors.transparent,
      borderColor: Colors.transparent,
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
    return oldDelegate.notchPath != notchPath || oldDelegate.shadows != shadows;
  }
}
