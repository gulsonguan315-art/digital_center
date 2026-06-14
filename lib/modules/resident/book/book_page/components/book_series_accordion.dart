import 'package:flutter/material.dart';
import '../../../../../core/engine/theme/theme_api.dart';
import '../../../../../core/data/models/book_data.dart';
import '../../../../../core/control/superfocus/focus_scroll_policy.dart';
import '../../../../../core/control/superfocus/focus_api.dart';
import '../../../../../core/layout/grid/grid_extensions.dart';
import '../../book_service.dart';
import '../../../../../ui/base/poster_card.dart';

typedef BookGridItemSlotBuilder =
    Widget Function(
      BuildContext context,
      BookItem item,
      Widget Function(
        BuildContext context,
        bool hasFocus,
        VoidCallback onTap, {
        required BookItem item,
      })
      builder, {
      VoidCallback? onTapOverride,
    });

class BookSeriesAccordionPanel extends StatelessWidget {
  final bool isExpanded;
  final GlobalKey expandKey;
  final double gap;
  final double cardHeight;
  final String? seriesId;
  final List<BookItem> children;
  final bool isLoadingChildren;
  final SliverGridDelegate gridDelegate;
  final int cols;
  final BookGridItemSlotBuilder gridItemSlot;

  const BookSeriesAccordionPanel({
    super.key,
    required this.isExpanded,
    required this.expandKey,
    required this.gap,
    required this.cardHeight,
    required this.seriesId,
    required this.children,
    required this.isLoadingChildren,
    required this.gridDelegate,
    required this.cols,
    required this.gridItemSlot,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      onEnd: () {
        final ctx = expandKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: 1.0,
          );
        }
      },
      child: !isExpanded
          ? const SizedBox.shrink()
          : Builder(
              builder: (ctx) {
                final colors = ctx.useTheme().colors;
                return Container(
                  key: expandKey,
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
                  clipBehavior: Clip.antiAlias,
                  child: isLoadingChildren
                      ? SizedBox(
                          height: cardHeight,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : children.isEmpty
                      ? SizedBox(
                          height: cardHeight,
                          child: Center(
                            child: Text(
                              '合集内暂无数据\n(此部分目前尚未实现具体网络请求)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: ctx.units(1.8),
                              ),
                            ),
                          ),
                        )
                      : SuperFocusRoom(
                          id: 'bookExpand_$seriesId',
                          child: FocusScrollPolicy(
                            boundary: const FocusScrollBoundary(
                              left: 0.0,
                              right: 0.0,
                              top: 0.0,
                              bottom: 0.0,
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: gridDelegate,
                              itemCount: children.length,
                              itemBuilder: (context, childIdx) {
                                final childItem = children[childIdx];
                                return gridItemSlot(
                                  context,
                                  childItem,
                                  (context, hasFocus, onTap, {required item}) {
                                    return PosterCard(
                                      title: item.title,
                                      subtitle: item.author.isNotEmpty
                                          ? item.author
                                          : '未知作者',
                                      imageUrl: item.coverPath.isEmpty
                                          ? 'assets/book_cover.png'
                                          : BookService.instance
                                              .getCoverArtUrl(item.id),
                                      badgeText: item.isSeries
                                          ? '合集 (${item.numBooks})'
                                          : null,
                                      isFocused: hasFocus,
                                      onTap: onTap,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                );
              },
            ),
    );
  }
}
