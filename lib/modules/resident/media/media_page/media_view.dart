import 'package:flutter/material.dart';
import '../../../../core/data/models/media_item.dart';
import '../../../../core/control/superfocus/focus_scroll_policy.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../../core/layout/grid/grid_extensions.dart';

import '../media_service.dart';
import '../../../../ui/base/poster_card.dart';
import 'components/skeleton_grid.dart';
import 'components/box_set_accordion.dart';

// 🖥️ 影视中心主视图排版 (Media Page Layout)
// =============================================================================

class MediaPageView extends StatefulWidget {
  final String category;
  final String? expandedBoxSetId;
  final Widget Function(
    BuildContext context,
    MediaItem item,
    Widget Function(
      BuildContext context,
      bool hasFocus,
      VoidCallback onTap, {
      required MediaItem item,
    })
    builder, {
    VoidCallback? onTapOverride,
  })
  gridItemSlot;

  const MediaPageView({
    super.key,
    required this.category,
    this.expandedBoxSetId,
    required this.gridItemSlot,
  });

  @override
  State<MediaPageView> createState() => _MediaPageViewState();
}

class _MediaPageViewState extends State<MediaPageView> {
  final GlobalKey _expandKey = GlobalKey();

  String _subtitle(MediaItem item) {
    final parts = <String>[];
    if (item.year != null) parts.add(item.year.toString());
    if (item.genre != null) parts.add(item.genre!.split(' / ').first);
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final service = MediaService.instance;
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
            // ── 海报网格 ─────────────────────────────────────────────────────
            Expanded(
              child: Builder(
                builder: (ctx) {
                  final colors = ctx.useTheme().colors;
                  final items = service.items;
                  final state = service.loadState;

                  // 加载中 + 空列表 → 显示骨架屏
                  if (state == MediaLoadState.loading && items.isEmpty) {
                    return LayoutBuilder(builder: (context, constraints) {
                      final double gap = context.units(2);
                      final double cardHeight = (constraints.maxHeight - 3 * gap) / 2.5;
                      final double aspectRatio = 0.72;
                      final double cardWidth = cardHeight * aspectRatio;
                      return SkeletonGrid(
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        gap: gap,
                        aspectRatio: aspectRatio,
                      );
                    });
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
                      int expandedIndex = -1;
                      if (widget.expandedBoxSetId != null) {
                        expandedIndex = items.indexWhere(
                          (e) => e.id == widget.expandedBoxSetId,
                        );
                      }

                      // 用户需求：一列正好显示 2.5 张海报，顶部 0.25，底部 0.25
                      // 完美公式：屏幕总高度 = 0.25张 + 间距 + 1张 + 间距 + 1张 + 间距 + 0.25张
                      // H = 2.5 * C + 3 * Gap
                      final double gap = context.units(2);
                      final double cardHeight = (constraints.maxHeight - 3 * gap) / 2.5;
                      final double aspectRatio = 0.72;
                      final double cardWidth = cardHeight * aspectRatio;

                      final double rawCols =
                          (constraints.maxWidth + gap) / (cardWidth + gap);
                      final int cols = rawCols.floor().clamp(1, 100);

                      final double verticalPadding = cardHeight * 0.25 + gap;

                      final gridDelegate =
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: gap,
                            mainAxisSpacing: gap,
                            childAspectRatio: aspectRatio,
                          );

                      // 计算切断位置
                      final int splitIndex = expandedIndex == -1
                          ? items.length
                          : ((expandedIndex ~/ cols) + 1) * cols;
                      final int topCount = splitIndex > items.length
                          ? items.length
                          : splitIndex;
                      final int bottomCount = items.length - topCount;

                      // 取出合集子项
                      final List<MediaItem> children = widget.expandedBoxSetId != null
                          ? (service.boxSetChildrenCache[widget.expandedBoxSetId!] ?? <MediaItem>[])
                          : <MediaItem>[];
                      final bool isLoadingChildren = children.isEmpty;

                      return FocusScrollPolicy(
                        boundary: FocusScrollBoundary(
                          left: 0.0,
                          right: 0.0,
                          top: verticalPadding,
                          bottom: verticalPadding,
                        ),
                        child: CustomScrollView(
                          cacheExtent: 1000.0,
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.only(top: verticalPadding),
                              sliver: SliverGrid(
                                gridDelegate: gridDelegate,
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final item = items[index];
                                  return widget.gridItemSlot(context, item, (
                                    context,
                                    hasFocus,
                                    onTap, {
                                    required item,
                                  }) {
                                    return PosterCard(
                                      title: item.title,
                                      subtitle: _subtitle(item),
                                      imageUrl: item.posterTag != null
                                        ? MediaService.instance.posterUrl(item.id, item.posterTag)
                                        : null,
                                      badgeText: item.jellyfinType == 'BoxSet' ? '合集' : null,
                                      cornerText: item.rating != null ? '★ ${item.rating!.toStringAsFixed(1)}' : null,
                                      isFocused: hasFocus,
                                      onTap: onTap,
                                    );
                                  });
                                }, childCount: topCount),
                              ),
                            ),

                            // ── 展开区域 (手风琴) ──
                            SliverToBoxAdapter(
                              child: BoxSetAccordionPanel(
                                isExpanded: expandedIndex != -1,
                                expandKey: _expandKey,
                                gap: gap,
                                cardHeight: cardHeight,
                                boxSetId: widget.expandedBoxSetId,
                                children: children,
                                isLoadingChildren: isLoadingChildren,
                                gridDelegate: gridDelegate,
                                cols: cols,
                                gridItemSlot: widget.gridItemSlot,
                              ),
                            ),

                            // ── 下半部分 ──
                            if (bottomCount > 0)
                              SliverGrid(
                                gridDelegate: gridDelegate,
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final realIndex = topCount + index;
                                  final item = items[realIndex];
                                  return widget.gridItemSlot(context, item, (
                                    context,
                                    hasFocus,
                                    onTap, {
                                    required item,
                                  }) {
                                    return PosterCard(
                                      title: item.title,
                                      subtitle: _subtitle(item),
                                      imageUrl: item.posterTag != null
                                        ? MediaService.instance.posterUrl(item.id, item.posterTag)
                                        : null,
                                      badgeText: item.jellyfinType == 'BoxSet' ? '合集' : null,
                                      cornerText: item.rating != null ? '★ ${item.rating!.toStringAsFixed(1)}' : null,
                                      isFocused: hasFocus,
                                      onTap: onTap,
                                    );
                                  });
                                }, childCount: bottomCount),
                              ),
                            SliverPadding(
                              padding: EdgeInsets.only(bottom: verticalPadding),
                            ),
                          ],
                        ),
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

