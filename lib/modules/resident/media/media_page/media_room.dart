import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/control/superfocus/interaction_manager.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../../core/stage/stage_contract.dart';
import '../../../../core/stage/stage_models.dart';
import '../../../../core/stage/stage_registry.dart';
import '../../../../core/stage/stage_hero_transition.dart';
import '../media_model.dart';
import 'media_view.dart';
import '../media_service.dart';
import 'media_callback.dart';
import '../media_detail/media_detail_room.dart';
import '../../../../core/stage/stage_manager.dart';
import '../../../overlay/media/media_immersive_overlay.dart';

/// 📂 影视页面主房间 (Media Room - Composition Root)
class MediaRoom extends StatefulWidget {
  final Widget? child;
  const MediaRoom({super.key, this.child});

  static const String roomId = MediaModel.mediaPageId;

  static void register() {
    StageRegistry.register(
      StageContract(
        roomId: 'media_overlay',
        zone: StageZone.thirdFloor_overlay,
        keepAlive: false,
        builder: (context) {
          final params = MediaService.instance.immersiveParams;
          if (params == null) return const SizedBox.shrink();
          return MediaImmersiveOverlay(
            itemId: params.itemId,
            mediaType: params.mediaType,
            startPositionTicks: params.startPositionTicks,
            forceStartOver: params.forceStartOver,
          );
        },
      ),
    );

    StageRegistry.register(
      StageContract(
        roomId: roomId,
        zone: StageZone.firstFloor_main,
        keepAlive: true,
        builder: (context) => const MediaRoom(),
      ),
    );

    // 🌟 注册通配符详情页 (支持全局 Hero 转场)
    StageRegistry.register(
      StageContract(
        roomId: 'movieDetail_*',
        zone: StageZone.secondFloor_screen,
        keepAlive: false,
        dynamicBuilder: (context, fullRoomId) {
          final id = fullRoomId.replaceFirst('movieDetail_', '');
          return MediaDetailRoom(roomId: fullRoomId, itemId: id);
        },
        customTransition: (context, child, isVisible, heroRect) =>
            StageHeroTransition(
              isVisible: isVisible,
              heroRect: heroRect,
              child: child,
            ),
        exitDelay: const Duration(milliseconds: 350),
      ),
    );

    StageRegistry.register(
      StageContract(
        roomId: 'seriesDetail_*',
        zone: StageZone.secondFloor_screen,
        keepAlive: false,
        dynamicBuilder: (context, fullRoomId) {
          final id = fullRoomId.replaceFirst('seriesDetail_', '');
          return MediaDetailRoom(roomId: fullRoomId, itemId: id);
        },
        customTransition: (context, child, isVisible, heroRect) =>
            StageHeroTransition(
              isVisible: isVisible,
              heroRect: heroRect,
              child: child,
            ),
        exitDelay: const Duration(milliseconds: 350),
      ),
    );
  }

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
          ListenableBuilder(
            listenable: Listenable.merge([
              SuperFocusManager.instance.topologyNotifier,
              StageManager.instance.isTransitioning,
            ]),
            builder: (context, _) {
              final topology =
                  SuperFocusManager.instance.topologyNotifier.value;

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
                    gridItemSlot:
                        (context, item, innerBuilder, {onTapOverride}) {
                          final focusId = item.id;

                          void action(BuildContext ctx) {
                            // 🌟 现在焦点系统会自动抓取并报告当前游标物理坐标，这里无需再手动计算 Rect!
                            onTapOverride != null
                                ? onTapOverride()
                                : MediaCallback.onMediaPosterTap(
                                    ctx,
                                    item,
                                    expandedBoxSetId,
                                  );
                          }

                          return ThemeIdentity(
                            role: ThemeRole.card,
                            child: Builder(
                              builder: (context) {
                                final material = context.useTheme();
                                return FocusIdentity(
                                  id: focusId,
                                  onPressed: () => action(context),
                                  alignment: FocusAlignment.keepVisible,
                                  focusGeometry: RoundedRectFocusGeometry(
                                    borderRadius: material.shape.radius,
                                  ),
                                  builder: (ctx, hasFocus) => innerBuilder(
                                    ctx,
                                    hasFocus,
                                    () => action(ctx), // Pass the inner context
                                    item: item,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                  );

                  return StageFirstFloor(child: gridView);
                },
              );
            },
          ),
    );
  }
}
