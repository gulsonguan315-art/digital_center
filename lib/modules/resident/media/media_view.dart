import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
import 'media_model.dart';

/// 🖼️ 影视海报卡片组件 (Media Poster Card Component)
class MediaCard extends StatelessWidget {
  final MediaItem item;
  final bool isFocused;
  final VoidCallback onTap;

  const MediaCard({
    super.key,
    required this.item,
    required this.isFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 动态确定层级：聚焦时使用 ThemeLayer.above，否则为 ThemeLayer.base 托付材质管理
    final layer = isFocused ? ThemeLayer.above : ThemeLayer.base;

    return ThemeIdentity(
      role: ThemeRole.card,
      layer: layer,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();
          final colors = material.colors;
          final chrome = material.visual;

          // 依据主题设计，在聚焦时动态应用主题内发光或投影
          final List<BoxShadow>? shadows = isFocused
              ? chrome.outerShadows
                  .map(
                    (e) => BoxShadow(
                      color: e.color,
                      offset: e.offset,
                      blurRadius: e.blurRadius,
                    ),
                  )
                  .toList()
              : null;

          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: material.shape.radius,
                border: Border.all(
                  color: isFocused ? colors.accent : colors.border,
                  width: isFocused ? 2.0 : 1.5,
                ),
                boxShadow: shadows,
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedScale(
                scale: isFocused ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 海报图区域：暂无物理图片数据，使用元数据渐变及播放器 Icon 渲染
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: item.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            size: context.units(4.0), // 对齐网格单位，缩放时完美等比缩小
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                    // 影视元数据文字排版区
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.units(1.1),
                        vertical: context.units(0.9),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: context.units(1.2), // 对齐网格单位
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.units(0.4)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.year} • ${item.genre.split(' / ').first}',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: context.units(1.0), // 对齐网格单位
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.units(0.4),
                                  vertical: context.units(0.1),
                                ),
                                decoration: BoxDecoration(
                                  color: colors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '★ ${item.rating}',
                                  style: TextStyle(
                                    color: colors.accent,
                                    fontSize: context.units(0.9), // 对齐网格单位
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 🖥️ 影视中心主视图排版 (Media Page Layout)
class MediaPageView extends StatelessWidget {
  final String category;
  final Widget Function(
    BuildContext context,
    int index,
    Widget Function(
      BuildContext context,
      bool hasFocus,
      VoidCallback onTap, {
      required MediaItem item,
    })
    builder,
  )
  gridItemSlot;

  const MediaPageView({
    super.key,
    required this.category,
    required this.gridItemSlot,
  });

  @override
  Widget build(BuildContext context) {
    final activeLabel = MediaModel.categoryLabels[category] ?? '影视中心 / Media';
    final items = MediaModel.mockItems
        .where((item) => item.category == category)
        .toList();

    // 🌟 排版原理高度优先：卡片高度在不同分辨率的屏幕上行数都是一样的
    final double cardHeight = context.units(28); // 影视卡片高度固定为 28 个网格单位
    final double aspectRatio = 0.72;             // 典型海报宽高比 (宽/高)
    final double cardWidth = cardHeight * aspectRatio;
    final double gap = context.units(2);         // 卡片间距固定为 2 个网格单位

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.units(4), // 页面两侧内边距对齐网格单位
          vertical: context.units(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 头部标题 ──────────────────────────────────────────────────────
            Builder(
              builder: (ctx) {
                final colors = ctx.useTheme().colors;
                return Text(
                  activeLabel,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: ctx.units(3.5), // 标题字号对齐网格单位
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                );
              },
            ),
            SizedBox(height: context.units(2)),

            // ── 影视卡片海报网格 ───────────────────────────────────────────────
            Expanded(
              child: items.isEmpty
                  ? Builder(
                      builder: (ctx) {
                        final colors = ctx.useTheme().colors;
                        return Center(
                          child: Text(
                            '该分类下暂无影视内容',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: ctx.units(2.0),
                            ),
                          ),
                        );
                      },
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final containerWidth = constraints.maxWidth;
                        // 根据高度求宽度计算列数 (列数 = (容器宽度 + 间距) / (单列宽度 + 间距))
                        final double rawCols = (containerWidth + gap) / (cardWidth + gap);
                        final int cols = rawCols.floor().clamp(1, 100);

                        return GridView.builder(
                          padding: EdgeInsets.only(bottom: context.units(4)),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: gap,
                            mainAxisSpacing: gap,
                            childAspectRatio: aspectRatio, // 保持完美的海报宽高比
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return gridItemSlot(
                              context,
                              index,
                              (context, hasFocus, onTap, {required item}) {
                                return MediaCard(
                                  item: item,
                                  isFocused: hasFocus,
                                  onTap: onTap,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
