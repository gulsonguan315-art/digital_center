import 'package:superfocus/core/layout/grid/grid_breakpoints.dart';

/// GridSpec 定义整套隐形网格的静态规则。
/// 它只负责公式和常量，不持有任何运行时状态。
class GridSpec {
  const GridSpec({
    this.baseRows = 100,
    this.semanticColumns = 24,
    this.minRuntimeColumns = 12,
    this.maxRuntimeColumns = 240,
    this.pageInsetUnits = 4,
    this.sectionGapUnits = 2,
  }) : assert(baseRows > 0),
       assert(semanticColumns > 0),
       assert(minRuntimeColumns > 0),
       assert(maxRuntimeColumns >= minRuntimeColumns),
       assert(pageInsetUnits >= 0),
       assert(sectionGapUnits >= 0);

  static const GridSpec standard = GridSpec();

  final int baseRows;
  final int semanticColumns;
  final int minRuntimeColumns;
  final int maxRuntimeColumns;
  final double pageInsetUnits;
  final double sectionGapUnits;

  double computeUnit(double viewportHeight) {
    if (viewportHeight <= 0) return 0;
    return viewportHeight / baseRows;
  }

  int computeColumnCount({
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final unit = computeUnit(viewportHeight);
    if (unit <= 0 || viewportWidth <= 0) {
      return minRuntimeColumns;
    }
    return ((viewportWidth / unit).floor()).clamp(
          minRuntimeColumns,
          maxRuntimeColumns,
        ).toInt();
  }

  GridBreakpoint resolveBreakpoint(double aspectRatio) {
    return GridBreakpoints.resolve(aspectRatio);
  }
}
