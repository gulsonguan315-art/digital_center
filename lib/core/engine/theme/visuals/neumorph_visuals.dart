import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme_visuals.dart';

double get _globalNeumorphOffset => 5.0;
double get _globalNeumorphPrimaryHighlightAlpha => 0.0;
double get _globalNeumorphPrimaryHighlightBlur => 20.0;
double get _globalNeumorphPrimaryShadowAlpha => 0.35;
double get _globalNeumorphPrimaryShadowBlur => 10.0;

double get _globalNeumorphSecondaryOffset => 4.0;
double get _globalNeumorphSecondaryHighlightAlpha => 0.0;
double get _globalNeumorphSecondaryHighlightBlur => 5.0;
double get _globalNeumorphSecondaryShadowAlpha => 0.55;
double get _globalNeumorphSecondaryShadowBlur => 5.0;

double get _globalNeumorphBorderWidth => 1.0;
double get _globalNeumorphBorderAlpha => 0.2;
double get _globalNeumorphBorderBlur => 1.0;
double get _globalNeumorphInnerHighlightWidth => 1.0;
double get _globalNeumorphInnerHighlightAlpha => 0.0;
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
  @override
  SurfaceChrome resolve({
    required Color accent,
    required Color border,
    required Color surface,
    required SurfaceState state,
  }) {
    final surfaceColor = state.fillColor ?? surface;
    return _buildChrome(
      border: border,
      surfaceColor: surfaceColor,
      scale: state.isWaiting || state.isFocused ? focusedScale : idleScale,
      isConcave: state.isConcave,
    );
  }

  SurfaceChrome _buildChrome({
    required Color border,
    required Color surfaceColor,
    required double scale,
    required bool isConcave,
  }) {
    final borderColor = border.withValues(alpha: _globalNeumorphBorderAlpha);
    final resolvedInnerHighlightColor = innerHighlightColor?.withValues(
      alpha: _globalNeumorphInnerHighlightAlpha,
    );

    return SurfaceChrome(
      outerShadows: isConcave
          ? const []
          : _buildNeumorphShadows(surfaceColor, scale),
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
