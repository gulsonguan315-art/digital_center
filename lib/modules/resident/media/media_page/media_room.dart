import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/control/superfocus/interaction_manager.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../media_model.dart';
import 'media_view.dart';
import '../media_service.dart';
import 'media_callback.dart';
import '../media_detail/media_detail_room.dart';

/// 📂 影视页面主房间 (Media Room - Composition Root)
class MediaRoom extends StatefulWidget {
  final Widget? child;
  const MediaRoom({super.key, this.child});

  static const String roomId = MediaModel.mediaPageId;

  @override
  State<MediaRoom> createState() => _MediaRoomState();
}

class _MediaRoomState extends State<MediaRoom> {
  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: MediaModel.mediaPageId,
      child:
          widget.child ??
          ValueListenableBuilder<FocusTopology>(
            valueListenable: SuperFocusManager.instance.topologyNotifier,
            builder: (context, topology, _) {
              final isActive = topology.activePath.contains(
                MediaModel.mediaPageId,
              );
              final isEntering =
                  SuperFocusManager.instance.intentionRoomId.value ==
                  MediaModel.mediaPageId;

              // 页面不活跃且未在进入意图中，跳过渲染节省 GPU
              if (!isActive && !isEntering) {
                return const SizedBox.shrink();
              }

              // 判断是否在详情页
              final String? movieDetailId =
                  topology.activeRoom?.startsWith('movieDetail_') == true
                  ? topology.activeRoom!.replaceFirst('movieDetail_', '')
                  : null;
              final String? seriesDetailId =
                  topology.activeRoom?.startsWith('seriesDetail_') == true
                  ? topology.activeRoom!.replaceFirst('seriesDetail_', '')
                  : null;

              // 判断是否有合集展开
              String? expandedBoxSetId;
              for (final path in topology.activePath) {
                if (path.startsWith('mediaExpand_')) {
                  expandedBoxSetId = path.replaceFirst('mediaExpand_', '');
                  break;
                }
              }

              // 订阅 MediaService 状态（分类 / 条目列表 / 加载状态）
              return ListenableBuilder(
                listenable: MediaService.instance,
                builder: (context, _) {
                  final service = MediaService.instance;
                  final activeCategory = service.selectedCategory;

                  final gridView = MediaPageView(
                    key: const ValueKey('media_grid'),
                    category: activeCategory,
                    expandedBoxSetId: expandedBoxSetId,
                    gridItemSlot: (context, item, innerBuilder, {onTapOverride}) {
                      final focusId = item.id;

                      void action() => onTapOverride != null
                          ? onTapOverride()
                          : MediaCallback.onMediaPosterTap(item, expandedBoxSetId);

                      return ThemeIdentity(
                        role: ThemeRole.card,
                        child: Builder(
                          builder: (context) {
                            final material = context.useTheme();
                            return FocusIdentity(
                              id: focusId,
                              onPressed: action,
                              ensureVisibleEdge: true,
                              focusGeometry: RoundedRectFocusGeometry(
                                borderRadius: material.shape.radius,
                              ),
                              builder: (ctx, hasFocus) => innerBuilder(
                                ctx,
                                hasFocus,
                                action,
                                item: item,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );

                  return Stack(
                    children: [
                      // 底层海报墙 (保持挂载以维持滚动状态)
                      gridView,

                      // 顶层详情页覆盖
                      if (movieDetailId != null || seriesDetailId != null)
                        Positioned.fill(
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(movieDetailId ?? seriesDetailId),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: seriesDetailId != null
                                ? MediaDetailRoom(
                                    roomId: 'seriesDetail_$seriesDetailId',
                                    itemId: seriesDetailId,
                                  ) // 临时复用，后续可替换为 SeriesDetailRoom
                                : MediaDetailRoom(
                                    roomId: 'movieDetail_$movieDetailId',
                                    itemId: movieDetailId!,
                                  ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
    );
  }
}
