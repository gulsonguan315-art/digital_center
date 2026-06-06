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

      return switch (direction) {
        TraversalDirection.up => target.bottom <= source.top + 1.0,
        TraversalDirection.down => target.top >= source.bottom - 1.0,
        TraversalDirection.left => target.right <= source.left + 1.0,
        TraversalDirection.right => target.left >= source.right - 1.0,
      };
    }).toList();

    if (candidates.isEmpty) return null;
    return _chooseBestCandidate(currentNode, candidates, direction);
  }

  FocusNode? _chooseBestCandidate(
    FocusNode currentNode,
    List<FocusNode> candidates,
    TraversalDirection direction,
  ) {
    final Rect source = currentNode.rect;
    final FocusNode? currentCluster = _getClusterNode(currentNode);

    FocusNode? best;
    double minScore = double.infinity;

    for (final node in candidates) {
      final target = node.rect;
      
      final dxEdge = _intervalDistance(source.left, source.right, target.left, target.right);
      final dyEdge = _intervalDistance(source.top, source.bottom, target.top, target.bottom);

      final double majorAxis = switch (direction) {
        TraversalDirection.up || TraversalDirection.down => dyEdge,
        TraversalDirection.left || TraversalDirection.right => dxEdge,
      };
      final double minorAxis = switch (direction) {
        TraversalDirection.up || TraversalDirection.down => dxEdge,
        TraversalDirection.left || TraversalDirection.right => dyEdge,
      };

      // 采用 Android 系统的 FocusFinder 经典算法：13 * major^2 + minor^2
      // 完美平衡 "正方向稍远" 与 "偏离轴线但更近" 之间的竞争
      double score = 13.0 * majorAxis * majorAxis + minorAxis * minorAxis;

      // ！！！ 核心引力机制 ！！！
      // （性能保障：如果当前焦点不在任何 Cluster 中，此段逻辑会被直接跳过，零性能损耗）
      // 如果候选节点和当前节点位于同一个 FocusCluster 中，
      // 我们将其距离得分缩小 10000 倍，这等同于在空间上把它们“拉得很近”，优先被选中。
      if (currentCluster != null) {
        if (_getClusterNode(node) == currentCluster) {
          score /= 10000.0;
        }
      }

      // 引入中心点距离作为打破平局（同在一条线上）的次要条件
      if (score == minScore) {
        final dCenter = (target.center - source.center).distanceSquared;
        final bestCenter = (best!.rect.center - source.center).distanceSquared;
        if (dCenter < bestCenter) {
          best = node;
        }
      } else if (score < minScore) {
        minScore = score;
        best = node;
      }
    }
    return best;
  }

  double _intervalDistance(double min1, double max1, double min2, double max2) {
    if (max1 < min2) return min2 - max1;
    if (max2 < min1) return min1 - max2;
    return 0.0;
  }

  FocusNode? _getClusterNode(FocusNode node) {
    FocusNode? parent = node.parent;
    while (parent != null && parent != node.nearestScope) {
      if (parent.debugLabel == 'FocusCluster') return parent;
      parent = parent.parent;
    }
    return null;
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
