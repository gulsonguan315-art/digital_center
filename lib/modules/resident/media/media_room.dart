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

              // 如果页面不活跃且未在进入意图中，直接跳过渲染以节省 GPU 资源
              if (!isActive && !isEntering) {
                return const SizedBox.shrink();
              }

              // 订阅 MediaService 状态，并在分类变更时自动重绘海报墙
              return ListenableBuilder(
                listenable: MediaService.instance,
                builder: (context, _) {
                  final activeCategory = MediaService.instance.selectedCategory;
                  final items = MediaModel.mockItems
                      .where((item) => item.category == activeCategory)
                      .toList();

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
                            // 🌟 解决问题 3：在 ThemeIdentity(role: ThemeRole.card) 上下文中获取卡片圆角，确保高亮框也是圆角而不会退化为直角
                            final material = context.useTheme();

                            return FocusIdentity(
                              id: focusId,
                              onPressed: action,
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
