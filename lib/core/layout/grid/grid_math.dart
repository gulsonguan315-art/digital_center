class GridMath {
  const GridMath._();

  static int clampSpan(
    int value, {
    required int min,
    required int max,
  }) {
    if (max < min) return min;
    return value.clamp(min, max).toInt();
  }

  static int semanticSpanToRuntime({
    required int semanticSpan,
    required int semanticColumns,
    required int runtimeColumns,
  }) {
    if (semanticSpan <= 0 || semanticColumns <= 0 || runtimeColumns <= 0) {
      return 1;
    }
    final mapped = (semanticSpan / semanticColumns) * runtimeColumns;
    return mapped.round().clamp(1, runtimeColumns).toInt();
  }

  static int runtimeOffsetToColumns({
    required int semanticOffset,
    required int semanticColumns,
    required int runtimeColumns,
  }) {
    if (semanticOffset <= 0) return 0;
    return semanticSpanToRuntime(
      semanticSpan: semanticOffset,
      semanticColumns: semanticColumns,
      runtimeColumns: runtimeColumns,
    ).clamp(0, runtimeColumns).toInt();
  }

  static double unitsToPixels(double units, double unitSize) {
    return units * unitSize;
  }

  static double columnsToPixels({
    required int columns,
    required double unitSize,
  }) {
    return columns * unitSize;
  }
}
