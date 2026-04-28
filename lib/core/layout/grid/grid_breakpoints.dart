enum GridBreakpoint {
  narrow,
  standard,
  wide,
  ultraWide,
}

class GridBreakpointRule {
  const GridBreakpointRule({
    required this.breakpoint,
    required this.minAspectRatio,
  });

  final GridBreakpoint breakpoint;
  final double minAspectRatio;
}

class GridBreakpoints {
  const GridBreakpoints._();

  static const List<GridBreakpointRule> defaults = [
    GridBreakpointRule(
      breakpoint: GridBreakpoint.ultraWide,
      minAspectRatio: 2.1,
    ),
    GridBreakpointRule(
      breakpoint: GridBreakpoint.wide,
      minAspectRatio: 1.78,
    ),
    GridBreakpointRule(
      breakpoint: GridBreakpoint.standard,
      minAspectRatio: 1.3,
    ),
    GridBreakpointRule(
      breakpoint: GridBreakpoint.narrow,
      minAspectRatio: 0,
    ),
  ];

  static GridBreakpoint resolve(double aspectRatio) {
    for (final rule in defaults) {
      if (aspectRatio >= rule.minAspectRatio) {
        return rule.breakpoint;
      }
    }
    return GridBreakpoint.narrow;
  }
}
