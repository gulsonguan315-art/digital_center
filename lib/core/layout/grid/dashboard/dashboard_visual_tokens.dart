import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:superfocus/core/layout/grid/grid_tokens.dart';

@immutable
class DashboardVisualTokens {
  const DashboardVisualTokens({
    required this.contentInset,
    required this.toolbarTopOffset,
    required this.toolbarGap,
    required this.loadingCardSize,
    required this.loadingIndicatorStrokeWidth,
    required this.resizeHandleInset,
    required this.overlayRadius,
    required this.overlayBorderWidth,
    required this.overlayBlur,
    required this.overlaySpread,
    required this.overlayLabelInset,
    required this.overlayLabelPadding,
    required this.overlayLabelRadius,
    required this.overlayLabelFontSize,
    required this.resizeHandleSize,
    required this.resizeHandleIconSize,
    required this.resizeHandleRadius,
    required this.resizeHandleBlur,
    required this.mockCardRadius,
    required this.mockCardBorderWidth,
    required this.mockCardFontSize,
  });

  factory DashboardVisualTokens.fromGridTokens(GridTokens gridTokens) {
    return DashboardVisualTokens(
      contentInset: EdgeInsets.all(gridTokens.pageInset),
      toolbarTopOffset: -gridTokens.spaceSm * 0.5,
      toolbarGap: gridTokens.spaceXs,
      loadingCardSize: gridTokens.cardMd.size,
      loadingIndicatorStrokeWidth: max(2.0, gridTokens.focusInset * 0.75),
      resizeHandleInset: -gridTokens.spaceXs,
      overlayRadius: gridTokens.focusRadius * 1.5,
      overlayBorderWidth: max(1.0, gridTokens.focusInset * 0.3),
      overlayBlur: gridTokens.spaceLg,
      overlaySpread: gridTokens.spaceXs * 0.125,
      overlayLabelInset: EdgeInsets.all(gridTokens.spaceXs),
      overlayLabelPadding: EdgeInsets.symmetric(
        horizontal: gridTokens.spaceXs,
        vertical: gridTokens.spaceXs * 0.5,
      ),
      overlayLabelRadius: 999,
      overlayLabelFontSize: max(11.0, gridTokens.spaceXs * 0.7),
      resizeHandleSize: gridTokens.spaceMd + gridTokens.spaceLg * 0.5,
      resizeHandleIconSize: gridTokens.spaceSm + gridTokens.spaceXs * 0.25,
      resizeHandleRadius: gridTokens.focusRadius,
      resizeHandleBlur: gridTokens.spaceMd,
      mockCardRadius: gridTokens.focusRadius * 1.5,
      mockCardBorderWidth: max(1.5, gridTokens.focusInset * 0.8),
      mockCardFontSize: max(14.0, gridTokens.spaceSm * 0.9),
    );
  }

  final EdgeInsets contentInset;
  final double toolbarTopOffset;
  final double toolbarGap;
  final Size loadingCardSize;
  final double loadingIndicatorStrokeWidth;
  final double resizeHandleInset;
  final double overlayRadius;
  final double overlayBorderWidth;
  final double overlayBlur;
  final double overlaySpread;
  final EdgeInsets overlayLabelInset;
  final EdgeInsets overlayLabelPadding;
  final double overlayLabelRadius;
  final double overlayLabelFontSize;
  final double resizeHandleSize;
  final double resizeHandleIconSize;
  final double resizeHandleRadius;
  final double resizeHandleBlur;
  final double mockCardRadius;
  final double mockCardBorderWidth;
  final double mockCardFontSize;
}
