import 'package:flutter/material.dart';
import '../../../../core/data/models/media_item.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../../core/layout/grid/grid_extensions.dart';
import '../media_model.dart';
import '../media_service.dart';
import 'media_callback.dart';
import '../../../../core/control/superfocus/focus_api.dart';

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
    final layer = isFocused ? ThemeLayer.above : ThemeLayer.base;

    return ThemeIdentity(
      role: ThemeRole.card,
      layer: layer,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();
          final colors = material.colors;
          final chrome = material.visual;

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
                    // ── 海报图区域 ───────────────────────────────────────────────
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PosterImage(
                            item: item,
                            placeholder: colors.backgroundFocused,
                          ),
                          if (item.jellyfinType == 'BoxSet')
                            Positioned(
                              top: context.units(0.8),
                              right: context.units(0.8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.units(0.6),
                                  vertical: context.units(0.3),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '合集',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.units(0.9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // ── 元数据文字排版区 ─────────────────────────────────────────
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
                              fontSize: context.units(1.2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.units(0.4)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _subtitle(item),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: context.units(1.0),
                                  ),
                                ),
                              ),
                              if (item.rating != null)
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
                                    '★ ${item.rating!.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      color: colors.accent,
                                      fontSize: context.units(0.9),
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

  String _subtitle(MediaItem item) {
    final parts = <String>[];
    if (item.year != null) parts.add(item.year.toString());
    if (item.genre != null) parts.add(item.genre!.split(' / ').first);
    return parts.join(' • ');
  }
}

/// 海报图片组件：优先 Image.network，无海报 Tag 时显示占位色块
class PosterImage extends StatelessWidget {
  final MediaItem item;
  final Color placeholder;

  const PosterImage({super.key, required this.item, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    final url = item.posterTag != null
        ? MediaService.instance.posterUrl(item.id, item.posterTag)
        : '';

    if (url.isEmpty) {
      return PlaceholderView(color: placeholder);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return PlaceholderView(color: placeholder);
      },
      errorBuilder: (_, e, s) => PlaceholderView(color: placeholder),
    );
  }
}

/// 无海报时的占位色块（使用主题 surfaceVariant 色）
class PlaceholderView extends StatelessWidget {
  final Color color;
  const PlaceholderView({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: context.units(4.0),
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

// =============================================================================
// 🖥️ 影视中心主视图排版 (Media Page Layout)
// =============================================================================

class MediaPageView extends StatelessWidget {
  final String category;
  final String? expandedBoxSetId;
  final Widget Function(
    BuildContext context,
    int index,
    Widget Function(
      BuildContext context,
      bool hasFocus,
      VoidCallback onTap, {
      required MediaItem item,
    }) builder,
  ) gridItemSlot;

  const MediaPageView({
    super.key,
    required this.category,
    this.expandedBoxSetId,
    required this.gridItemSlot,
  });

  @override
  Widget build(BuildContext context) {
    final service = MediaService.instance;
    final activeLabel = MediaModel.categoryLabels[category] ?? '影视中心 / Media';

    // 高度优先网格参数
    final double cardHeight = context.units(28);
    final double aspectRatio = 0.72;
    final double cardWidth = cardHeight * aspectRatio;
    final double gap = context.units(2);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.units(4),
          vertical: context.units(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 头部标题 ────────────────────────────────────────────────────
            Builder(
              builder: (ctx) {
                final colors = ctx.useTheme().colors;
                return Text(
                  activeLabel,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: ctx.units(3.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                );
              },
            ),
            SizedBox(height: context.units(2)),

            // ── 海报网格 ─────────────────────────────────────────────────────
            Expanded(
              child: Builder(
                builder: (ctx) {
                  final colors = ctx.useTheme().colors;
                  final items = service.items;
                  final state = service.loadState;

                  // 加载中 + 空列表 → 显示骨架屏
                  if (state == MediaLoadState.loading && items.isEmpty) {
                    return SkeletonGrid(
                      cardWidth: cardWidth,
                      cardHeight: cardHeight,
                      gap: gap,
                      aspectRatio: aspectRatio,
                    );
                  }

                  // 加载完成但空列表 → 提示
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        '该分类下暂无影视内容',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: ctx.units(2.0),
                        ),
                      ),
                    );
                  }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final double rawCols =
                              (constraints.maxWidth + gap) / (cardWidth + gap);
                          final int cols = rawCols.floor().clamp(1, 100);

                          int expandedIndex = -1;
                          if (expandedBoxSetId != null) {
                            expandedIndex = items.indexWhere((e) => e.id == expandedBoxSetId);
                          }

                          final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: gap,
                            mainAxisSpacing: gap,
                            childAspectRatio: aspectRatio,
                          );

                          // 如果没有展开项，直接渲染完整 Grid
                          if (expandedIndex == -1) {
                            return CustomScrollView(
                              slivers: [
                                SliverGrid(
                                  gridDelegate: gridDelegate,
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      return gridItemSlot(
                                        context,
                                        index,
                                        (context, hasFocus, onTap, {required item}) {
                                          return MediaCard(item: item, isFocused: hasFocus, onTap: onTap);
                                        },
                                      );
                                    },
                                    childCount: items.length,
                                  ),
                                ),
                                SliverPadding(padding: EdgeInsets.only(bottom: context.units(4))),
                              ],
                            );
                          }

                          // 计算切断位置
                          final int splitIndex = ((expandedIndex ~/ cols) + 1) * cols;
                          final int topCount = splitIndex > items.length ? items.length : splitIndex;
                          final int bottomCount = items.length - topCount;

                          // 取出合集子项
                          final children = service.boxSetChildrenCache[expandedBoxSetId!] ?? [];
                          final bool isLoadingChildren = children.isEmpty;

                          return CustomScrollView(
                            slivers: [
                              // ── 上半部分 ──
                              if (topCount > 0)
                                SliverGrid(
                                  gridDelegate: gridDelegate,
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      return gridItemSlot(
                                        context,
                                        index,
                                        (context, hasFocus, onTap, {required item}) {
                                          return MediaCard(item: item, isFocused: hasFocus, onTap: onTap);
                                        },
                                      );
                                    },
                                    childCount: topCount,
                                  ),
                                ),

                              // ── 展开区域 (手风琴) ──
                              SliverToBoxAdapter(
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: gap),
                                    padding: EdgeInsets.all(gap),
                                    decoration: BoxDecoration(
                                      color: colors.surface.withValues(alpha: 0.85),
                                      borderRadius: ctx.useTheme().shape.radius,
                                      border: Border.all(
                                        color: colors.accent.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isLoadingChildren
                                        ? SizedBox(
                                            height: cardHeight,
                                            child: const Center(child: CircularProgressIndicator()),
                                          )
                                        : SuperFocusRoom(
                                            id: 'mediaExpand_$expandedBoxSetId',
                                            child: GridView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              gridDelegate: gridDelegate,
                                              itemCount: children.length,
                                              itemBuilder: (context, childIdx) {
                                                final childItem = children[childIdx];
                                                return ThemeIdentity(
                                                  role: ThemeRole.card,
                                                  child: Builder(builder: (c) {
                                                    return FocusIdentity(
                                                      id: childItem.id,
                                                      onPressed: () {
                                                        MediaCallback.onBoxSetChildTap(childItem, expandedBoxSetId!);
                                                      },
                                                      ensureVisibleEdge: true,
                                                      focusGeometry: RoundedRectFocusGeometry(
                                                        borderRadius: c.useTheme().shape.radius,
                                                      ),
                                                      builder: (c, hasFocus) => MediaCard(
                                                        item: childItem,
                                                        isFocused: hasFocus,
                                                        onTap: () {
                                                          MediaCallback.onBoxSetChildTap(childItem, expandedBoxSetId!);
                                                        },
                                                      ),
                                                    );
                                                  }),
                                                );
                                              },
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              // ── 下半部分 ──
                              if (bottomCount > 0)
                                SliverGrid(
                                  gridDelegate: gridDelegate,
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final realIndex = topCount + index;
                                      return gridItemSlot(
                                        context,
                                        realIndex,
                                        (context, hasFocus, onTap, {required item}) {
                                          return MediaCard(item: item, isFocused: hasFocus, onTap: onTap);
                                        },
                                      );
                                    },
                                    childCount: bottomCount,
                                  ),
                                ),
                              SliverPadding(padding: EdgeInsets.only(bottom: context.units(4))),
                            ],
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

/// 骨架屏：加载中时显示灰色占位卡片
class SkeletonGrid extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final double gap;
  final double aspectRatio;

  const SkeletonGrid({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.gap,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double rawCols =
            (constraints.maxWidth + gap) / (cardWidth + gap);
        final int cols = rawCols.floor().clamp(1, 100);

        return GridView.builder(
          padding: EdgeInsets.only(bottom: context.units(4)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: aspectRatio,
          ),
          itemCount: cols * 3, // 显示约 3 行骨架
          itemBuilder: (context, index) {
            return Builder(
              builder: (ctx) {
                final colors = ctx.useTheme().colors;
                return Container(
                  decoration: BoxDecoration(
                    color: colors.backgroundFocused.withValues(alpha: 0.5),
                    borderRadius: ctx.useTheme().shape.radius,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
