import 'package:flutter/widgets.dart';
import 'package:superfocus/core/layout/grid/grid_context.dart';
import 'package:superfocus/core/layout/grid/grid_scope.dart';
import 'package:superfocus/core/layout/grid/grid_tokens.dart';

extension GridContextX on BuildContext {
  GridContext get grid => GridScope.gridContextOf(this);

  GridTokens get gridTokens => GridScope.gridTokensOf(this);

  double get u => grid.unit;

  double units(double value) => grid.units(value);

  double columns(double value) => grid.columns(value);
}
