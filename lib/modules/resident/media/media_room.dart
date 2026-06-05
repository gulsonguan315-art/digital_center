import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/control/superfocus/interaction_manager.dart';
import '../../../core/engine/theme/theme_api.dart';
import 'media_model.dart';
import 'media_view.dart';
import 'media_service.dart';

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

              // 订阅 MediaService 状态（分类 / 条目列表 / 加载状态）
              return ListenableBuilder(
                listenable: MediaService.instance,
                builder: (context, _) {
                  final service = MediaService.instance;
                  final activeCategory = service.selectedCategory;
                  final items = service.items;

                  return MediaPageView(
                    category: activeCategory,
                    gridItemSlot: (context, index, innerBuilder) {
                      if (index >= items.length) return const SizedBox.shrink();
                      final item = items[index];
                      final focusId = item.id;

                      void action() {
                        debugPrint('🎬 激活影视卡片：${item.title} (ID: ${item.id})');
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
                },
              );
            },
          ),
    );
  }
}
