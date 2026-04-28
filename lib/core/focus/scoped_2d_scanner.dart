import 'package:flutter/widgets.dart';

/// Scoped 2D 几何扫描仪
/// 声明式作用域隔离：遵循“不在一个作用域就看不到”的直觉准则。
class Scoped2dScanner extends FocusTraversalPolicy {
  final String debugLabel;

  const Scoped2dScanner({this.debugLabel = 'Scoped2DScanner'});

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final nextFocus = findFirstFocusInDirection(currentNode, direction);
    if (nextFocus != null) {
      nextFocus.requestFocus();
      return true;
    }
    return false;
  }

  @override
  FocusNode? findFirstFocusInDirection(
    FocusNode currentNode,
    TraversalDirection direction,
  ) {
    final scope = currentNode.nearestScope;
    if (scope == null) return null;

    final candidates = scope.traversalDescendants.where((node) {
      if (!_isMicroCandidate(node) || node == currentNode) return false;

      // 核心声明式逻辑：
      // 只有在同一个“直接作用域”下的节点，才被认为是有效的扫描目标。
      // 这可以防止扫描引擎“穿透”进深层的子房间作用域（子房间拥有自己的 FocusScope）。
      if (node.nearestScope != scope) return false;

      final target = node.rect;
      final source = currentNode.rect;

      switch (direction) {
        case TraversalDirection.up:
          return target.bottom <= source.top + 1.0;
        case TraversalDirection.down:
          return target.top >= source.bottom - 1.0;
        case TraversalDirection.left:
          return target.right <= source.left + 1.0;
        case TraversalDirection.right:
          return target.left >= source.right - 1.0;
      }
    }).toList();

    if (candidates.isEmpty) return null;
    return _chooseBestCandidate(currentNode.rect.center, candidates, direction);
  }

  FocusNode? _chooseBestCandidate(
    Offset source,
    List<FocusNode> candidates,
    TraversalDirection direction,
  ) {
    FocusNode? best;
    double minScore = double.infinity;

    for (final node in candidates) {
      final target = node.rect.center;
      final dx = (target.dx - source.dx).abs();
      final dy = (target.dy - source.dy).abs();

      double score;
      if (direction == TraversalDirection.up ||
          direction == TraversalDirection.down) {
        score = dy + (dx * 2.0);
      } else {
        score = dx + (dy * 2.0);
      }

      if (score < minScore) {
        minScore = score;
        best = node;
      }
    }
    return best;
  }

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    final scope = currentNode.nearestScope;
    return descendants.where(
      (node) => _isMicroCandidate(node) && node.nearestScope == scope,
    );
  }

  bool _isMicroCandidate(FocusNode node) {
    if (!node.canRequestFocus) return false;
    if (node is FocusScopeNode) return false;
    return true;
  }
}
