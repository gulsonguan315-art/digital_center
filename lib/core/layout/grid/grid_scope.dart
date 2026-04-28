import 'package:flutter/widgets.dart';
import 'package:superfocus/core/layout/grid/grid_context.dart';
import 'package:superfocus/core/layout/grid/grid_tokens.dart';

class GridScope extends InheritedWidget {
  const GridScope({
    super.key,
    required this.gridContext,
    required this.gridTokens,
    required super.child,
  });

  final GridContext gridContext;
  final GridTokens gridTokens;

  static GridScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GridScope>();
    assert(scope != null, 'GridScope not found in widget tree.');
    return scope!;
  }

  static GridContext gridContextOf(BuildContext context) {
    return of(context).gridContext;
  }

  static GridTokens gridTokensOf(BuildContext context) {
    return of(context).gridTokens;
  }

  @override
  bool updateShouldNotify(GridScope oldWidget) {
    return gridContext != oldWidget.gridContext ||
        gridTokens != oldWidget.gridTokens;
  }
}
