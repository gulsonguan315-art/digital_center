import '../../../../core/data/models/dashboard_item_config.dart';

/// 📏 看板网格布局边界策略 (Dashboard Grid Layout Boundary Policy)
/// 统一约束看板卡片在平移与缩放时的边界尺寸，保证布局不溢出。
class DashboardLayoutPolicy {
  const DashboardLayoutPolicy._();

  /// 栅格最大列数限制 (例如 12 列网格)
  static const int maxColumns = 12;

  /// 栅格最大垂直行高限制
  static const int maxRowLimit = 100;

  /// 对看板卡片的位置和大小进行统一的边界归一化策略约束。
  /// 确保卡片不会在右侧溢出 (x + spanX <= maxColumns)。
  static DashboardItemConfig normalize(DashboardItemConfig item) {
    final spanX = item.spanX.clamp(1, maxColumns);
    final spanY = item.spanY.clamp(1, maxRowLimit);
    final x = item.x.clamp(0, maxColumns - spanX);
    final y = item.y.clamp(0, maxRowLimit - spanY);

    return item.copyWith(
      x: x,
      y: y,
      spanX: spanX,
      spanY: spanY,
    );
  }
}
