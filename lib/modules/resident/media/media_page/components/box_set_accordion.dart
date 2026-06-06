import 'package:flutter/material.dart';
import '../../../../../core/engine/theme/theme_api.dart';
import '../../../../../core/data/models/media_item.dart';
import '../../../../../core/control/superfocus/focus_scroll_policy.dart';
import '../../../../../core/control/superfocus/focus_api.dart';
import '../media_callback.dart';
import '../../media_service.dart';
import '../../../../../ui/base/poster_card.dart';

typedef GridItemSlotBuilder = Widget Function(
  BuildContext context,
  MediaItem item,
  Widget Function(
    BuildContext context,
    bool hasFocus,
    VoidCallback onTap, {
    required MediaItem item,
  }) builder, {
  VoidCallback? onTapOverride,
});

class BoxSetAccordionPanel extends StatelessWidget {
  final bool isExpanded;
  final GlobalKey expandKey;
  final double gap;
  final double cardHeight;
  final String? boxSetId;
  final List<MediaItem> children;
  final bool isLoadingChildren;
  final SliverGridDelegate gridDelegate;
  final int cols;
  final GridItemSlotBuilder gridItemSlot;

  const BoxSetAccordionPanel({
    super.key,
    required this.isExpanded,
    required this.expandKey,
    required this.gap,
    required this.cardHeight,
    required this.boxSetId,
    required this.children,
    required this.isLoadingChildren,
    required this.gridDelegate,
    required this.cols,
    required this.gridItemSlot,
  });

  String _subtitle(MediaItem item) {
    final parts = <String>[];
    if (item.year != null) parts.add(item.year.toString());
    if (item.genre != null) parts.add(item.genre!.split(' / ').first);
    return parts.join(' • ');
  }

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
            alignment: 1.0, // 确保底部对齐，这样下边缘不会被裁掉
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
                      : SuperFocusRoom(
                          id: 'mediaExpand_$boxSetId',
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
                                return TweenAnimationBuilder<double>(
                                  key: ValueKey(childItem.id),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 600),
                                  builder: (context, value, child) {
                                    final delay = (childIdx % cols) * 0.08 +
                                        (childIdx ~/ cols) * 0.04;
                                    final progress =
                                        ((value - delay) / (1.0 - delay))
                                            .clamp(0.0, 1.0);
                                    final curvedProgress =
                                        Curves.easeOutCubic.transform(progress);
                                    return Transform.translate(
                                      offset: Offset(
                                          0, (1.0 - curvedProgress) * -150.0),
                                      child: Opacity(
                                        opacity: curvedProgress,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: gridItemSlot(
                                    context,
                                    childItem,
                                    (context, hasFocus, onTap, {required item}) {
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
                                    },
                                    onTapOverride: () {
                                      if (boxSetId != null) {
                                        MediaCallback.onBoxSetChildTap(
                                          childItem,
                                          boxSetId!,
                                        );
                                      }
                                    },
                                  ),
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
