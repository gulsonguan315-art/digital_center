import 'package:flutter/material.dart';
import '../../../core/data/data_manager.dart';
import '../../../core/data/models/poetry_data.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../ui/base/text/surface_text.dart';
import '../../../ui/base/surface/dashboard_card.dart';

/// 📂 诗词卡片挂件 (Dedicated Poetry Card Widget)
/// 响应式订阅“数据总管理员 (DataManager)”，结合离线缓存实现 0 延时开屏秒开。
class PoetryView extends StatelessWidget {
  const PoetryView({super.key});

  /// 🛡️ 业务层自主排版清洗逻辑：实现“智能名句过滤模式”与原装“两两合并对联模式”的完美结合
  String _formatPoetryContent(List<String> paragraphs, List<int> markedLines) {
    if (paragraphs.isEmpty) return '';

    // 🌟 核心设计：如果有用户标记高亮过的诗句，则 Dashboard 上仅收拢展示这些“专属划线格言”
    if (markedLines.isNotEmpty) {
      final List<String> curated = [];
      for (final idx in markedLines) {
        if (idx >= 0 && idx < paragraphs.length) {
          curated.add(paragraphs[idx]);
        }
      }
      return curated.join('\n');
    }

    // 🌟 兜底逻辑：若尚未打标，则默认按两两合并的对联模式展示全文，维持视觉张力
    if (paragraphs.length <= 2) return paragraphs.join(' ');
    final List<String> lines = [];
    for (int i = 0; i < paragraphs.length; i += 2) {
      if (i + 1 < paragraphs.length) {
        lines.add('${paragraphs[i]}${paragraphs[i + 1]}');
      } else {
        lines.add(paragraphs[i]);
      }
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.useTheme();
    final colors = theme.colors;

    return StreamBuilder<PoetryData>(
      stream: DataManager.instance.watchTodayPoetry(),
      initialData: DataManager.instance.latestPoetry,
      builder: (context, snapshot) {
        final data = snapshot.data ?? DataManager.instance.latestPoetry;
        final displayContent = _formatPoetryContent(
          data.paragraphs,
          data.markedLines,
        );

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
                  // 动态诗词核心金句 (Main poetry line)
                  Center(
                    child: SurfaceText(
                      displayContent,
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
                  // 动态出处及作者落款 (Author & Title citation block)
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
                        '${data.author} · 《${data.title}》',
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
      },
    );
  }
}
