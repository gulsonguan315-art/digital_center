import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_colors.dart';
import '../theme_visuals.dart';

double get _globalNeumorphOffset => 5.0;
double get _globalNeumorphPrimaryHighlightAlpha => 0.0;
double get _globalNeumorphPrimaryHighlightBlur => 20.0;
double get _globalNeumorphPrimaryShadowAlpha => 0.35;
double get _globalNeumorphPrimaryShadowBlur => 10.0;

double get _globalNeumorphSecondaryOffset => 4.0;
double get _globalNeumorphSecondaryHighlightAlpha => 0.0;
double get _globalNeumorphSecondaryHighlightBlur => 5.0;
double get _globalNeumorphSecondaryShadowAlpha => 0.35;
double get _globalNeumorphSecondaryShadowBlur => 5.0;

double get _globalNeumorphBorderWidth => 5.5;
double get _globalNeumorphBorderAlpha => 0.0;
double get _globalNeumorphBorderBlur => 5.0;
double get _globalNeumorphInnerHighlightWidth => 1.0;
double get _globalNeumorphInnerHighlightAlpha => 1.0;
double get _globalNeumorphInnerHighlightBlur => 0.0;

double get _cardIdleScale => 0.8;
double get _cardFocusedScale => 1.0;
double get _panelIdleScale => 1.0;
double get _panelFocusedScale => 1.0;
double get _foregroundShadowScale => 0.35;

List<BoxShadow> _buildNeumorphShadows(Color surfaceColor, double scale) {
  final primaryDelta = _globalNeumorphOffset * scale;
  final secondaryDelta = _globalNeumorphSecondaryOffset * scale;

  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: _globalNeumorphPrimaryShadowAlpha),
      offset: Offset(primaryDelta, primaryDelta),
      blurRadius: _globalNeumorphPrimaryShadowBlur,
    ),
    BoxShadow(
      color: Colors.white.withValues(
        alpha: _globalNeumorphPrimaryHighlightAlpha,
      ),
      offset: Offset(-primaryDelta, -primaryDelta),
      blurRadius: _globalNeumorphPrimaryHighlightBlur,
    ),
    BoxShadow(
      color: surfaceColor.withValues(
        alpha: _globalNeumorphSecondaryHighlightAlpha,
      ),
      offset: Offset(-secondaryDelta, -secondaryDelta),
      blurRadius: _globalNeumorphSecondaryHighlightBlur,
    ),
    BoxShadow(
      color: surfaceColor.withValues(
        alpha: _globalNeumorphSecondaryShadowAlpha,
      ),
      offset: Offset(secondaryDelta, secondaryDelta),
      blurRadius: _globalNeumorphSecondaryShadowBlur,
    ),
  ];
}

List<Shadow> _buildForegroundShadows(Color foregroundColor, double scale) {
  final primaryDelta = _globalNeumorphOffset * scale;
  final secondaryDelta = _globalNeumorphSecondaryOffset * scale;

  return [
    Shadow(
      color: Colors.black.withValues(alpha: _globalNeumorphPrimaryShadowAlpha),
      offset: Offset(primaryDelta, primaryDelta),
      blurRadius: _globalNeumorphPrimaryShadowBlur,
    ),
    Shadow(
      color: foregroundColor.withValues(
        alpha: _globalNeumorphSecondaryHighlightAlpha,
      ),
      offset: Offset(-secondaryDelta, -secondaryDelta),
      blurRadius: _globalNeumorphSecondaryHighlightBlur,
    ),
    Shadow(
      color: foregroundColor.withValues(
        alpha: _globalNeumorphSecondaryShadowAlpha,
      ),
      offset: Offset(secondaryDelta, secondaryDelta),
      blurRadius: _globalNeumorphSecondaryShadowBlur,
    ),
  ];
}

class NeumorphSurfaceEffect extends SurfaceEffect {
  final double borderThickness;
  final bool transparentIdle;
  final double idleScale;
  final double focusedScale;
  final Color? innerHighlightColor;
  final double innerHighlightWidth;

  const NeumorphSurfaceEffect({
    required this.borderThickness,
    required this.idleScale,
    required this.focusedScale,
    this.innerHighlightColor,
    this.innerHighlightWidth = 0,
    this.transparentIdle = false,
  });

  @override
  Widget apply(
    BuildContext context,
    Widget child, {
    required bool isFocused,
    bool isWaiting = false,
    BorderRadiusGeometry? borderRadius,
    Color? fillColor,
  }) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;
    final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;
    final radius = borderRadius ?? themeVisuals.defaultRadius;
    final surfaceColor = fillColor ?? themeColors.surfacePanel;
    final chrome = _buildChrome(
      themeColors: themeColors,
      surfaceColor: surfaceColor,
      scale: isWaiting || isFocused ? focusedScale : idleScale,
    );

    final bgColor = isWaiting
        ? themeColors.adormColor
        : (transparentIdle ? Colors.transparent : surfaceColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        boxShadow: chrome.outerShadows,
      ),
      child: CustomPaint(
        foregroundPainter:
            (chrome.borderColor == null || chrome.borderWidth <= 0) &&
                (chrome.innerHighlightColor == null ||
                    chrome.innerHighlightWidth <= 0)
            ? null
            : _NeumorphForegroundPainter(
                radius: radius,
                borderColor: chrome.borderColor,
                borderWidth: chrome.borderWidth,
                borderBlur: chrome.borderBlur,
                innerHighlightColor: chrome.innerHighlightColor,
                innerHighlightWidth: chrome.innerHighlightWidth,
                innerHighlightBlur: chrome.innerHighlightBlur,
              ),
        child: child,
      ),
    );
  }

  @override
  SurfaceChrome chrome({
    required BuildContext context,
    required bool isFocused,
    bool isWaiting = false,
    Color? fillColor,
  }) {
    final themeColors = Theme.of(context).extension<ThemeColors>()!;
    final surfaceColor = fillColor ?? themeColors.surfacePanel;
    return _buildChrome(
      themeColors: themeColors,
      surfaceColor: surfaceColor,
      scale: isWaiting || isFocused ? focusedScale : idleScale,
    );
  }

  SurfaceChrome _buildChrome({
    required ThemeColors themeColors,
    required Color surfaceColor,
    required double scale,
  }) {
    final baseBorder = themeColors.surfaceBorder;
    final borderColor = baseBorder.withValues(alpha: _globalNeumorphBorderAlpha);
    final resolvedInnerHighlightColor = innerHighlightColor?.withValues(
      alpha: _globalNeumorphInnerHighlightAlpha,
    );

    return SurfaceChrome(
      outerShadows: _buildNeumorphShadows(surfaceColor, scale),
      borderColor: transparentIdle ? Colors.transparent : borderColor,
      borderWidth: transparentIdle
          ? 0
          : _globalNeumorphBorderWidth * borderThickness,
      borderBlur: transparentIdle ? 0 : _globalNeumorphBorderBlur,
      innerHighlightColor: resolvedInnerHighlightColor,
      innerHighlightWidth:
          innerHighlightWidth * _globalNeumorphInnerHighlightWidth,
      innerHighlightBlur: _globalNeumorphInnerHighlightBlur,
    );
  }

  @override
  List<Shadow> foregroundShadows({
    required BuildContext context,
    required Color foregroundColor,
    required bool isFocused,
    bool isWaiting = false,
    Color? fillColor,
  }) {
    final scale =
        (isWaiting || isFocused ? focusedScale : idleScale) *
        _foregroundShadowScale;
    return _buildForegroundShadows(foregroundColor, scale);
  }

  @override
  SurfaceEffect lerp(SurfaceEffect other, double t) {
    if (other is! NeumorphSurfaceEffect) return t < 0.5 ? this : other;
    return NeumorphSurfaceEffect(
      borderThickness:
          ui.lerpDouble(borderThickness, other.borderThickness, t) ??
          borderThickness,
      idleScale: ui.lerpDouble(idleScale, other.idleScale, t) ?? idleScale,
      focusedScale:
          ui.lerpDouble(focusedScale, other.focusedScale, t) ?? focusedScale,
      innerHighlightColor: Color.lerp(
        innerHighlightColor,
        other.innerHighlightColor,
        t,
      ),
      innerHighlightWidth:
          ui.lerpDouble(innerHighlightWidth, other.innerHighlightWidth, t) ??
          innerHighlightWidth,
      transparentIdle: t < 0.5 ? transparentIdle : other.transparentIdle,
    );
  }
}

class _NeumorphForegroundPainter extends CustomPainter {
  const _NeumorphForegroundPainter({
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
    final rect = Offset.zero & size;
    final resolved = radius.resolve(TextDirection.ltr);
    final outerRRect = resolved.toRRect(rect);

    canvas.save();
    canvas.clipRRect(outerRRect);

    if (borderColor != null && borderWidth > 0) {
      final inset = borderWidth / 2;
      final borderRect = Rect.fromLTWH(
        inset,
        inset,
        size.width - (inset * 2),
        size.height - (inset * 2),
      );
      final borderRRect = resolved.toRRect(borderRect);
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..maskFilter = borderBlur > 0
            ? MaskFilter.blur(BlurStyle.normal, borderBlur)
            : null;
      canvas.drawRRect(borderRRect, borderPaint);
    }

    if (innerHighlightColor != null && innerHighlightWidth > 0) {
      final inset = innerHighlightWidth / 2;
      final highlightRect = Rect.fromLTWH(
        inset,
        inset,
        size.width - (inset * 2),
        size.height - (inset * 2),
      );
      final highlightRRect = resolved.toRRect(highlightRect);
      final highlightPaint = Paint()
        ..color = innerHighlightColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerHighlightWidth
        ..maskFilter = innerHighlightBlur > 0
            ? MaskFilter.blur(BlurStyle.normal, innerHighlightBlur)
            : null;
      canvas.drawRRect(highlightRRect, highlightPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_NeumorphForegroundPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderBlur != borderBlur ||
        oldDelegate.innerHighlightColor != innerHighlightColor ||
        oldDelegate.innerHighlightWidth != innerHighlightWidth ||
        oldDelegate.innerHighlightBlur != innerHighlightBlur;
  }
}

ThemeVisuals get neumorphicVisuals => ThemeVisuals(
  buttonSurface: NeumorphSurfaceEffect(
    borderThickness: 0.5,
    idleScale: _cardIdleScale,
    focusedScale: _cardFocusedScale,
    innerHighlightColor: Color.fromARGB(255, 255, 255, 255),
    innerHighlightWidth: 2,
  ),
  switchSurface: NeumorphSurfaceEffect(
    borderThickness: 0.5,
    idleScale: _cardIdleScale,
    focusedScale: _cardFocusedScale,
    innerHighlightColor: Color.fromARGB(255, 255, 255, 255),
    innerHighlightWidth: 2,
    transparentIdle: true,
  ),
  panelSurface: NeumorphSurfaceEffect(
    borderThickness: 0.5,
    idleScale: _panelIdleScale,
    focusedScale: _panelFocusedScale,
    innerHighlightColor: Color.fromARGB(255, 255, 255, 255),
    innerHighlightWidth: 2,
  ),
  defaultRadius: BorderRadius.circular(24),
  focusGlowRadius: 30.0,
  focusGlowOpacity: 0.2,
);
