import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/engine/theme/theme_api.dart';

class ThemedSurface extends StatelessWidget {
  const ThemedSurface({
    super.key,
    required this.child,
    this.material,
    this.effect,
    this.isFocused = false,
    this.isWaiting = false,
    this.isConcave = false,
    this.borderRadius,
    this.fillColor,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final ResolvedThemeMaterial? material;
  final SurfaceEffect? effect;
  final bool isFocused;
  final bool isWaiting;
  final bool isConcave;
  final BorderRadiusGeometry? borderRadius;
  final Color? fillColor;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final resolvedMaterial = material ?? context.useTheme();
    final colors = resolvedMaterial.colors;
    final radius = borderRadius ?? resolvedMaterial.shape.radius;
    final visual = effect ?? resolvedMaterial.visual;
    final state = SurfaceState(
      isFocused: isFocused,
      isWaiting: isWaiting,
      isConcave: isConcave,
      fillColor: fillColor,
    );
    final chrome = visual.resolve(
      accent: colors.accent,
      border: colors.border,
      surface: colors.surface,
      state: state,
    );
    final baseColor = isWaiting ? colors.accent : (fillColor ?? colors.surface);
    final background = chrome.surfaceOpacity < 1.0
        ? baseColor.withValues(alpha: chrome.surfaceOpacity)
        : baseColor;

    Widget content = AnimatedContainer(
      duration: duration,
      curve: curve,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        boxShadow: chrome.outerShadows,
      ),
      child: Stack(
        children: [
          if (chrome.overlayGradientColors.isNotEmpty)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: chrome.overlayGradientColors,
                  ),
                ),
              ),
            ),
          if ((chrome.borderColor != null && chrome.borderWidth > 0) ||
              (chrome.innerHighlightColor != null &&
                  chrome.innerHighlightWidth > 0))
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SurfaceStrokePainter(
                    radius: radius,
                    borderColor: chrome.borderColor,
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
      ),
    );

    if (chrome.surfaceBlur > 0) {
      content = ClipRRect(
        borderRadius: radius,
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

class _SurfaceStrokePainter extends CustomPainter {
  const _SurfaceStrokePainter({
    required this.radius,
    this.borderColor,
    this.borderWidth = 0,
    this.borderBlur = 0,
    this.innerHighlightColor,
    this.innerHighlightWidth = 0,
    this.innerHighlightBlur = 0,
  });

  final BorderRadiusGeometry radius;
  final Color? borderColor;
  final double borderWidth;
  final double borderBlur;
  final Color? innerHighlightColor;
  final double innerHighlightWidth;
  final double innerHighlightBlur;

  @override
  void paint(Canvas canvas, Size size) {
    final resolved = radius.resolve(TextDirection.ltr);

    if (borderColor != null && borderWidth > 0) {
      _drawStroke(
        canvas,
        size,
        resolved,
        color: borderColor!,
        width: borderWidth,
        blur: borderBlur,
      );
    }

    if (innerHighlightColor != null && innerHighlightWidth > 0) {
      _drawStroke(
        canvas,
        size,
        resolved,
        color: innerHighlightColor!,
        width: innerHighlightWidth,
        blur: innerHighlightBlur,
      );
    }
  }

  void _drawStroke(
    Canvas canvas,
    Size size,
    BorderRadius resolved, {
    required Color color,
    required double width,
    required double blur,
  }) {
    final inset = width / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - (inset * 2),
      size.height - (inset * 2),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;

    canvas.drawRRect(resolved.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(_SurfaceStrokePainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderBlur != borderBlur ||
        oldDelegate.innerHighlightColor != innerHighlightColor ||
        oldDelegate.innerHighlightWidth != innerHighlightWidth ||
        oldDelegate.innerHighlightBlur != innerHighlightBlur;
  }
}
