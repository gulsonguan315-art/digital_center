import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';

/// 一个纯粹的视觉容器，带有卡口标题和边框。
/// 仅负责 UI 渲染，不包含任何焦点逻辑。
class GroupFrame extends StatelessWidget {
  final String title;
  final bool isHighlighted;
  final Widget child;
  final double width;

  const GroupFrame({
    super.key,
    required this.title,
    required this.child,
    this.isHighlighted = false,
    this.width = 500,
  });

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final colors = material.colors;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. 底层线框
        Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
          decoration: BoxDecoration(
            borderRadius: material.shape.radius,
            border: Border.all(
              color: colors.textPrimary.withValues(
                alpha: isHighlighted ? 0.2 : 0.05,
              ),
              width: 1,
            ),
          ),
          child: child,
        ),

        // 2. 嵌入在顶部的标题文字 (卡口效果)
        Positioned(
          top: -10,
          left: 32,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            color: colors.surface,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: colors.textPrimary.withValues(
                  alpha: isHighlighted ? 0.8 : 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
