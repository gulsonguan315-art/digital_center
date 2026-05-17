import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../ui/base/text/surface_text.dart';
import '../../../ui/base/surface/dashboard_card.dart';

/// 📂 诗词卡片挂件 (Dedicated Poetry Card Widget)
/// 与其它卡片如时钟 (ClockView) 一样，继承相同的视觉与排版体系，拥有高端社论质感。
class PoetryView extends StatelessWidget {
  const PoetryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.useTheme();
    final colors = theme.colors;

    return DashboardCard(
      layer: ThemeLayer.base,
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 左上角巨型半透明前双引号装饰 (Large decorative opening quote mark)
          Positioned(
            top: -20,
            left: -10,
            child: Text(
              '“',
              style: TextStyle(
                fontSize: 100,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.bold,
                color: colors.accent.withValues(alpha: 0.12),
                height: 1,
              ),
            ),
          ),
          // 2. 右下角巨型半透明后双引号装饰 (Large decorative closing quote mark)
          Positioned(
            bottom: -60,
            right: -10,
            child: Text(
              '”',
              style: TextStyle(
                fontSize: 100,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.bold,
                color: colors.accent.withValues(alpha: 0.12),
                height: 1,
              ),
            ),
          ),
          // 3. 诗词主体内容区
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // 诗词核心金句 (Main poetry line)
              Center(
                child: SurfaceText(
                  '落霞与孤鹜齐飞，秋水共长天一色。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    letterSpacing: 2.5,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 出处及作者落款 (Author & Title citation block)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 16,
                    height: 1,
                    color: colors.accent.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 8),
                  SurfaceText(
                    '王勃 · 《滕王阁序》',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary.withValues(alpha: 0.7),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}
