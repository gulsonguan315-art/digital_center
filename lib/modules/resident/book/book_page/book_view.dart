import 'package:flutter/material.dart';
import '../../../../core/data/models/book_data.dart';
import '../../../../core/control/superfocus/focus_scroll_policy.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../../core/layout/grid/grid_extensions.dart';

import '../book_service.dart';
import '../../../../ui/base/poster_card.dart';
import 'components/book_series_accordion.dart';

class BookPageView extends StatefulWidget {
  final String? expandedSeriesId;
  final BookGridItemSlotBuilder gridItemSlot;

  const BookPageView({
    super.key,
    this.expandedSeriesId,
    required this.gridItemSlot,
  });

  @override
  State<BookPageView> createState() => _BookPageViewState();
}

class _BookPageViewState extends State<BookPageView> {
  final GlobalKey _expandKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final service = BookService.instance;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Builder(
              builder: (ctx) {
                final colors = ctx.useTheme().colors;
                final items = service.items;
                final state = service.loadState;

                if (state == BookLoadState.loading && items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      '该分类下暂无图书内容',
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
                    if (widget.expandedSeriesId != null) {
                      expandedIndex = items.indexWhere((e) => e.id == widget.expandedSeriesId);
                    }

                    final double gap = context.units(2);
                    final double cardHeight = (constraints.maxHeight - 3 * gap) / 2.5;
                    final double aspectRatio = 0.72;
                    final double cardWidth = cardHeight * aspectRatio;

                    final double rawCols = (constraints.maxWidth + gap) / (cardWidth + gap);
                    final int cols = rawCols.floor().clamp(1, 100);

                    final double verticalPadding = cardHeight * 0.25 + gap;

                    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: gap,
                      mainAxisSpacing: gap,
                      childAspectRatio: aspectRatio,
                    );

                    final int splitIndex = expandedIndex == -1 ? items.length : ((expandedIndex ~/ cols) + 1) * cols;
                    final int topCount = splitIndex > items.length ? items.length : splitIndex;
                    final int bottomCount = items.length - topCount;

                    final List<BookItem> children = widget.expandedSeriesId != null
                        ? (service.seriesChildrenCache[widget.expandedSeriesId!] ?? <BookItem>[])
                        : <BookItem>[];
                    final bool isLoadingChildren = widget.expandedSeriesId != null &&
                        !service.seriesChildrenCache.containsKey(widget.expandedSeriesId!);

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
                              delegate: SliverChildBuilderDelegate((context, index) {
                                final item = items[index];
                                return widget.gridItemSlot(context, item, (context, hasFocus, onTap, {required item}) {
                                  return PosterCard(
                                    title: item.title,
                                    subtitle: item.author.isNotEmpty ? item.author : '未知作者',
                                    imageUrl: item.coverPath.isEmpty
                                        ? 'assets/book_cover.png'
                                        : service.getCoverArtUrl(item.id),
                                    badgeText: item.isSeries ? '合集 (${item.numBooks})' : null,
                                    isFocused: hasFocus,
                                    onTap: onTap,
                                  );
                                });
                              }, childCount: topCount),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: BookSeriesAccordionPanel(
                              isExpanded: expandedIndex != -1,
                              expandKey: _expandKey,
                              gap: gap,
                              cardHeight: cardHeight,
                              seriesId: widget.expandedSeriesId,
                              children: children,
                              isLoadingChildren: isLoadingChildren,
                              gridDelegate: gridDelegate,
                              cols: cols,
                              gridItemSlot: widget.gridItemSlot,
                            ),
                          ),

                          if (bottomCount > 0)
                            SliverGrid(
                              gridDelegate: gridDelegate,
                              delegate: SliverChildBuilderDelegate((context, index) {
                                final realIndex = topCount + index;
                                final item = items[realIndex];
                                return widget.gridItemSlot(context, item, (context, hasFocus, onTap, {required item}) {
                                  return PosterCard(
                                    title: item.title,
                                    subtitle: item.author.isNotEmpty ? item.author : '未知作者',
                                    imageUrl: item.coverPath.isEmpty
                                        ? 'assets/book_cover.png'
                                        : service.getCoverArtUrl(item.id),
                                    badgeText: item.isSeries ? '合集 (${item.numBooks})' : null,
                                    isFocused: hasFocus,
                                    onTap: onTap,
                                  );
                                });
                              }, childCount: bottomCount),
                            ),
                          SliverPadding(padding: EdgeInsets.only(bottom: verticalPadding)),
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
    );
  }
}
