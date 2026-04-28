import 'dart:ui';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:superfocus/core/layout/grid/grid_context.dart';

@immutable
class GridCardSize {
  const GridCardSize({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  Size get size => Size(width, height);
}

@immutable
class GridPosterScale {
  const GridPosterScale({
    required this.height,
    required this.width,
  });

  factory GridPosterScale.fromHeight(double height) {
    return GridPosterScale(
      height: height,
      width: height * (2 / 3),
    );
  }

  final double height;
  final double width;
}

@immutable
class GridTypographyTokens {
  const GridTypographyTokens({
    required this.fontXs,
    required this.fontSm,
    required this.fontMd,
    required this.fontLg,
    required this.fontXl,
    required this.titleSm,
    required this.titleMd,
    required this.titleLg,
    required this.caption,
    required this.label,
    required this.body,
    required this.button,
    required this.lineHeightTight,
    required this.lineHeightNormal,
    required this.lineHeightRelaxed,
  });

  factory GridTypographyTokens.fromUnit(double u) {
    return GridTypographyTokens(
      fontXs: max(11.0, u * 1.1),
      fontSm: max(12.0, u * 1.25),
      fontMd: max(14.0, u * 1.45),
      fontLg: max(16.0, u * 1.8),
      fontXl: max(20.0, u * 2.3),
      titleSm: max(16.0, u * 1.7),
      titleMd: max(20.0, u * 2.2),
      titleLg: max(24.0, u * 2.8),
      caption: max(11.0, u * 1.1),
      label: max(12.0, u * 1.25),
      body: max(14.0, u * 1.45),
      button: max(14.0, u * 1.35),
      lineHeightTight: 1.15,
      lineHeightNormal: 1.35,
      lineHeightRelaxed: 1.5,
    );
  }

  final double fontXs;
  final double fontSm;
  final double fontMd;
  final double fontLg;
  final double fontXl;
  final double titleSm;
  final double titleMd;
  final double titleLg;
  final double caption;
  final double label;
  final double body;
  final double button;
  final double lineHeightTight;
  final double lineHeightNormal;
  final double lineHeightRelaxed;
}

@immutable
class GridTokens {
  const GridTokens({
    required this.context,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.pageInset,
    required this.sectionGap,
    required this.sidebarWidth,
    required this.titleBlockHeight,
    required this.focusInset,
    required this.focusRadius,
    required this.posterSm,
    required this.posterMd,
    required this.posterLg,
    required this.cardSm,
    required this.cardMd,
    required this.cardLg,
    required this.typography,
  });

  factory GridTokens.fromContext(GridContext context) {
    final u = context.unit;
    return GridTokens(
      context: context,
      spaceXs: u,
      spaceSm: u * 2,
      spaceMd: u * 3,
      spaceLg: u * 4,
      spaceXl: u * 6,
      pageInset: context.pageInset,
      sectionGap: context.sectionGap,
      sidebarWidth: u * 14,
      titleBlockHeight: u * 8,
      focusInset: u * 0.75,
      focusRadius: u * 0.9,
      posterSm: GridPosterScale.fromHeight(u * 18),
      posterMd: GridPosterScale.fromHeight(u * 24),
      posterLg: GridPosterScale.fromHeight(u * 30),
      cardSm: GridCardSize(width: u * 12, height: u * 8),
      cardMd: GridCardSize(width: u * 16, height: u * 10),
      cardLg: GridCardSize(width: u * 24, height: u * 14),
      typography: GridTypographyTokens.fromUnit(u),
    );
  }

  final GridContext context;

  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;

  final double pageInset;
  final double sectionGap;
  final double sidebarWidth;
  final double titleBlockHeight;

  final double focusInset;
  final double focusRadius;

  final GridPosterScale posterSm;
  final GridPosterScale posterMd;
  final GridPosterScale posterLg;

  final GridCardSize cardSm;
  final GridCardSize cardMd;
  final GridCardSize cardLg;

  final GridTypographyTokens typography;
}
