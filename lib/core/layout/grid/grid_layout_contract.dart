import 'package:flutter/widgets.dart';
import 'package:superfocus/core/layout/grid/grid_breakpoints.dart';
import 'package:superfocus/core/layout/grid/grid_context.dart';
import 'package:superfocus/core/layout/grid/grid_span.dart';
import 'package:superfocus/core/layout/grid/grid_tokens.dart';

abstract class GridLayoutContract {
  const GridLayoutContract();

  GridSpan get baseSpan;

  GridSpan spanFor(GridContext context) {
    return switch (context.breakpoint) {
      GridBreakpoint.ultraWide => spanForUltraWide(context),
      GridBreakpoint.wide => spanForWide(context),
      GridBreakpoint.standard => spanForStandard(context),
      GridBreakpoint.narrow => spanForNarrow(context),
    };
  }

  GridSpan spanForUltraWide(GridContext context) => baseSpan;

  GridSpan spanForWide(GridContext context) => baseSpan;

  GridSpan spanForStandard(GridContext context) => baseSpan;

  GridSpan spanForNarrow(GridContext context) => baseSpan;

  EdgeInsetsGeometry paddingFor(GridTokens tokens) => EdgeInsets.zero;

  EdgeInsetsGeometry marginFor(GridTokens tokens) => EdgeInsets.zero;
}
