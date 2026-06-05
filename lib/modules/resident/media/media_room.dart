import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/control/superfocus/interaction_manager.dart';
import '../../../core/engine/theme/theme_api.dart';
import 'media_model.dart';
import 'media_view.dart';
import 'media_service.dart';
import 'media_detail_room.dart';

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
              final String? detailId = topology.activeRoom?.startsWith('mediaDetail_') == true 
                  ? topology.activeRoom!.replaceFirst('mediaDetail_', '')
                  : null;

              // 订阅 MediaService 状态（分类 / 条目列表 / 加载状态）
              return ListenableBuilder(
                listenable: MediaService.instance,
                builder: (context, _) {
                  final service = MediaService.instance;
                  final activeCategory = service.selectedCategory;
                  final items = service.items;

                  final gridView = MediaPageView(
                    key: const ValueKey('media_grid'),
                    category: activeCategory,
                    gridItemSlot: (context, index, innerBuilder) {
                      if (index >= items.length) return const SizedBox.shrink();
                      final item = items[index];
                      final focusId = item.id;

                      void action() {
                        FocusAPI.dispatchAction(MediaModel.mediaPageId, 'mediaDetail_${item.id}', asTerminalRoom: true);
                      }

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
                      if (detailId != null)
                        Positioned.fill(
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(detailId),
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
                            child: MediaDetailRoom(itemId: detailId),
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
