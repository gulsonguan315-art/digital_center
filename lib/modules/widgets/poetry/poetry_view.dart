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

    // 🌟 核心设计：如果有用户标记高亮过的诗句，则仅展示专属划线
    if (markedLines.isNotEmpty) {
      final List<String> curated = [];
      for (final idx in markedLines) {
        if (idx >= 0 && idx < paragraphs.length) {
          curated.add(paragraphs[idx]);
        }
      }
      return curated.join('\n');
    }

    // 🌟 兜底与排版逻辑：按照句号（。/？/！）进行物理换行展示，抛弃强行两两合并的粗暴排版
    final String fullText = paragraphs.join('').trim();
    String formatted;
    if (fullText.contains('。') || fullText.contains('？') || fullText.contains('！')) {
      formatted = fullText
          .replaceAll('。', '。\n')
          .replaceAll('？', '？\n')
          .replaceAll('！', '！\n')
          .replaceAll('\n\n', '\n') // 防御处理，避免产生双重换行
          .trim();
    } else {
      formatted = paragraphs.join('\n');
    }

    // 🌟 限高要求：无高亮显示全文时，默认最多显示 6 行，未显完则第 7 行显示省略号
    final List<String> lines = formatted
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length > 6) {
      final List<String> truncated = lines.take(6).toList();
      truncated.add('...');
      return truncated.join('\n');
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
                          fontWeight: FontWeight.normal,
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
