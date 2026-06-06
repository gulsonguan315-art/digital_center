// lib/core/control/superfocus/focus_scroll_engine.dart

import 'focus_alignment.dart';

class FocusScrollEngine {
  /// 计算单轴滚动补偿量
  static double calculateDelta({
    required double targetStart,
    required double targetEnd,
    required double viewportStart,
    required double viewportEnd,
    double? currentPixels,
    double paddingStart = 60.0,
    double paddingEnd = 60.0,
    FocusAlignment alignment = FocusAlignment.keepVisible,
  }) {
    final double safeStart = viewportStart + paddingStart;
    final double safeEnd = viewportEnd - paddingEnd;

    switch (alignment) {
      case FocusAlignment.center:
        final double safeCenter = safeStart + (safeEnd - safeStart) / 2.0;
        final double targetCenter = targetStart + (targetEnd - targetStart) / 2.0;
        return targetCenter - safeCenter;
        
      case FocusAlignment.top:
        return targetStart - safeStart;
        
      case FocusAlignment.bottom:
        return targetEnd - safeEnd;

      case FocusAlignment.viewportStart:
        return currentPixels != null ? -currentPixels : (targetStart - safeStart);
        
      case FocusAlignment.keepVisible:
        double delta = 0.0;
        // 1. 如果目标本身比安全区还大（罕见的超大卡片），优先保证头部对齐
        if ((targetEnd - targetStart) > (safeEnd - safeStart)) {
          delta = targetStart - safeStart; 
        }
        // 2. 撞到起始边界（左侧/上侧）
        else if (targetStart < safeStart) {
          delta = targetStart - safeStart;
        }
        // 3. 撞到结束边界（右侧/下侧）
        else if (targetEnd > safeEnd) {
          delta = targetEnd - safeEnd;
        }
        return delta;
    }
  }
}
