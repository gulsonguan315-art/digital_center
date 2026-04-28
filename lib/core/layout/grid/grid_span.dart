import 'package:flutter/foundation.dart';
import 'package:superfocus/core/layout/grid/grid_context.dart';

@immutable
class GridSpan {
  const GridSpan({
    required this.columns,
    this.rows = 1,
    this.offset = 0,
  }) : assert(columns > 0),
       assert(rows > 0),
       assert(offset >= 0);

  final int columns;
  final int rows;
  final int offset;

  int resolveColumns(GridContext context) {
    return context.semanticSpanToRuntime(columns);
  }

  int resolveOffset(GridContext context) {
    return context.semanticOffsetToRuntime(offset);
  }

  double resolveWidth(GridContext context) {
    return context.columns(resolveColumns(context).toDouble());
  }

  double resolveHeight(GridContext context) {
    return context.units(rows.toDouble());
  }

  GridSpan copyWith({
    int? columns,
    int? rows,
    int? offset,
  }) {
    return GridSpan(
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      offset: offset ?? this.offset,
    );
  }
}
