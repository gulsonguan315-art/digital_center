import 'dart:ui' as ui;

import 'package:flutter/material.dart';

abstract class FocusGeometry {
  const FocusGeometry();

  Path buildOutlinePath(Rect rect);

  Path? buildCutoutPath(Rect rect) => null;

  FocusGeometry lerpTo(FocusGeometry other, double t);
}

class RoundedRectFocusGeometry extends FocusGeometry {
  const RoundedRectFocusGeometry({this.borderRadius = BorderRadius.zero});

  final BorderRadiusGeometry borderRadius;

  @override
  Path buildOutlinePath(Rect rect) {
    // 解析 BorderRadiusGeometry 为具体的 BorderRadius
    final resolved = borderRadius.resolve(TextDirection.ltr);
    return Path()..addRRect(resolved.toRRect(rect));
  }

  @override
  FocusGeometry lerpTo(FocusGeometry other, double t) {
    if (other is RoundedRectFocusGeometry) {
      return RoundedRectFocusGeometry(
        borderRadius:
            BorderRadiusGeometry.lerp(borderRadius, other.borderRadius, t) ??
            borderRadius,
      );
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoundedRectFocusGeometry && borderRadius == other.borderRadius;

  @override
  int get hashCode => borderRadius.hashCode;
}

class SidebarTileFocusGeometry extends FocusGeometry {
  const SidebarTileFocusGeometry({
    required this.borderRadius,
    this.openRightness = 0.0,
    this.concaveRadius = 0.0,
  });

  final BorderRadiusGeometry borderRadius;
  final double openRightness;
  final double concaveRadius;

  bool get hasRightOpening => openRightness > 0.0;

  @override
  Path buildOutlinePath(Rect rect) {
    return _buildUPath(rect);
  }

  Path buildRightSegment(Rect rect) {
    final resolved = borderRadius.resolve(TextDirection.ltr).toRRect(rect);
    final path = Path();
    path.moveTo(rect.right - resolved.brRadiusX, rect.bottom);
    path.arcToPoint(
      Offset(rect.right, rect.bottom - resolved.brRadiusY),
      radius: Radius.elliptical(resolved.brRadiusX, resolved.brRadiusY),
      clockwise: false,
    );
    path.lineTo(rect.right, rect.top + resolved.trRadiusY);
    path.arcToPoint(
      Offset(rect.right - resolved.trRadiusX, rect.top),
      radius: Radius.elliptical(resolved.trRadiusX, resolved.trRadiusY),
      clockwise: false,
    );
    return path;
  }

  @override
  Path? buildCutoutPath(Rect rect) {
    if (!hasRightOpening || concaveRadius <= 0.0) {
      return null;
    }

    final resolved = borderRadius.resolve(TextDirection.ltr).toRRect(rect);
    final path = Path()..moveTo(rect.right, rect.top - concaveRadius);
    path.arcToPoint(
      Offset(rect.right - concaveRadius, rect.top),
      radius: Radius.circular(concaveRadius),
      clockwise: true,
    );
    path.lineTo(rect.left + resolved.tlRadiusX, rect.top);
    path.arcToPoint(
      Offset(rect.left, rect.top + resolved.tlRadiusY),
      radius: Radius.elliptical(resolved.tlRadiusX, resolved.tlRadiusY),
      clockwise: false,
    );
    path.lineTo(rect.left, rect.bottom - resolved.blRadiusY);
    path.arcToPoint(
      Offset(rect.left + resolved.blRadiusX, rect.bottom),
      radius: Radius.elliptical(resolved.blRadiusX, resolved.blRadiusY),
      clockwise: false,
    );
    path.lineTo(rect.right - concaveRadius, rect.bottom);
    path.arcToPoint(
      Offset(rect.right, rect.bottom + concaveRadius),
      radius: Radius.circular(concaveRadius),
      clockwise: true,
    );
    path.close();
    return path;
  }

  @override
  FocusGeometry lerpTo(FocusGeometry other, double t) {
    if (other is SidebarTileFocusGeometry) {
      return SidebarTileFocusGeometry(
        borderRadius:
            BorderRadiusGeometry.lerp(borderRadius, other.borderRadius, t) ??
            borderRadius,
        openRightness: ui.lerpDouble(openRightness, other.openRightness, t)!,
        concaveRadius: ui.lerpDouble(concaveRadius, other.concaveRadius, t)!,
      );
    }
    if (other is RoundedRectFocusGeometry) {
      return SidebarTileFocusGeometry(
        borderRadius:
            BorderRadiusGeometry.lerp(borderRadius, other.borderRadius, t) ??
            borderRadius,
        openRightness: ui.lerpDouble(openRightness, 0.0, t)!,
        concaveRadius: ui.lerpDouble(concaveRadius, 0.0, t)!,
      );
    }
    return t < 0.5 ? this : other;
  }

  Path _buildUPath(Rect rect) {
    final resolved = borderRadius.resolve(TextDirection.ltr).toRRect(rect);
    final path = Path();
    path.moveTo(rect.right - resolved.trRadiusX, rect.top);
    path.lineTo(rect.left + resolved.tlRadiusX, rect.top);
    path.arcToPoint(
      Offset(rect.left, rect.top + resolved.tlRadiusY),
      radius: Radius.elliptical(resolved.tlRadiusX, resolved.tlRadiusY),
      clockwise: false,
    );
    path.lineTo(rect.left, rect.bottom - resolved.blRadiusY);
    path.arcToPoint(
      Offset(rect.left + resolved.blRadiusX, rect.bottom),
      radius: Radius.elliptical(resolved.blRadiusX, resolved.blRadiusY),
      clockwise: false,
    );
    path.lineTo(rect.right - resolved.brRadiusX, rect.bottom);
    return path;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SidebarTileFocusGeometry &&
          borderRadius == other.borderRadius &&
          openRightness == other.openRightness &&
          concaveRadius == other.concaveRadius;

  @override
  int get hashCode => Object.hash(borderRadius, openRightness, concaveRadius);
}
