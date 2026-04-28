import 'package:flutter/material.dart';
import 'package:superfocus/core/layout/grid/grid_scope.dart';

// Lightweight debug surface for the new grid infrastructure.
class GridDebugOverlay extends StatelessWidget {
  const GridDebugOverlay({
    super.key,
    this.showGrid = false,
  });

  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final grid = GridScope.gridContextOf(context);
    final tokens = GridScope.gridTokensOf(context);

    return IgnorePointer(
      child: Stack(
        children: [
          if (showGrid && grid.unit > 0)
            Positioned.fill(
              child: CustomPaint(
                painter: _GridOverlayPainter(
                  unit: grid.unit,
                  color: Colors.cyanAccent.withValues(alpha: 0.12),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(
                  right: tokens.spaceSm,
                  bottom: tokens.spaceSm,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: _GridDebugInfo(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridDebugInfo extends StatelessWidget {
  const _GridDebugInfo();

  @override
  Widget build(BuildContext context) {
    final grid = GridScope.gridContextOf(context);
    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        height: 1.4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GRID DEBUG',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          _DebugLine(
            label: 'viewport',
            value:
                '${grid.viewportWidth.toStringAsFixed(1)} x ${grid.viewportHeight.toStringAsFixed(1)}',
          ),
          _DebugLine(
            label: 'u',
            value: grid.unit.toStringAsFixed(2),
          ),
          _DebugLine(
            label: 'columns',
            value: '${grid.columnCount}',
          ),
          _DebugLine(
            label: 'aspect',
            value: grid.aspectRatio.toStringAsFixed(3),
          ),
          _DebugLine(
            label: 'breakpoint',
            value: grid.breakpoint.name,
          ),
          _DebugLine(
            label: 'semantic',
            value: '${grid.spec.semanticColumns}',
          ),
        ],
      ),
    );
  }
}

class _DebugLine extends StatelessWidget {
  const _DebugLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text('$label: $value');
  }
}

class _GridOverlayPainter extends CustomPainter {
  const _GridOverlayPainter({
    required this.unit,
    required this.color,
  });

  final double unit;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double y = 0; y <= size.height; y += unit) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x <= size.width; x += unit) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GridOverlayPainter oldDelegate) {
    return oldDelegate.unit != unit || oldDelegate.color != color;
  }
}
