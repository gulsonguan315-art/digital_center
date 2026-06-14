import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/control/superfocus/interaction_manager.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../../core/stage/stage_contract.dart';
import '../../../../core/stage/stage_models.dart';
import '../../../../core/stage/stage_registry.dart';
import '../book_model.dart';
import '../book_service.dart';
import 'book_callback.dart';
import 'book_view.dart';
import '../../../../core/stage/stage_manager.dart';

/// 📚 图书页面主房间 (Book Room - Composition Root)
class BookRoom extends StatefulWidget {
  final Widget? child;
  const BookRoom({super.key, this.child});

  static const String roomId = BookModel.bookPageId;

  static void register() {
    StageRegistry.register(
      StageContract(
        roomId: roomId,
        zone: StageZone.firstFloor_main,
        keepAlive: true,
        builder: (context) => const BookRoom(),
      ),
    );
  }

  @override
  State<BookRoom> createState() => _BookRoomState();
}

class _BookRoomState extends State<BookRoom> {
  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: BookModel.bookPageId,
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
              final isActive = topology.activePath.contains(
                BookModel.bookPageId,
              );
              final isEntering =
                  SuperFocusManager.instance.intentionRoomId.value ==
                  BookModel.bookPageId;
              final isTransitioning =
                  StageManager.instance.isTransitioning.value;

              // 移除了 SizedBox.shrink() 激进卸载。
              // 因为 StageView 已经使用了 Offstage + TickerMode 来包裹非活跃房间，
              // 这已经足够阻断重绘和动画以节省 GPU。
              // 如果强制 shrink 卸载，会导致内部的所有 FocusNode 销毁，从而破坏传送门弹栈（Portal Return）时的焦点记忆！

              // 判断是否有合集展开
              String? expandedSeriesId;
              for (final path in topology.activePath) {
                if (path.startsWith('bookExpand_')) {
                  expandedSeriesId = path.replaceFirst('bookExpand_', '');
                  break;
                }
              }

              return ListenableBuilder(
                listenable: BookService.instance,
                builder: (context, _) {
                  final gridView = BookPageView(
                    key: const ValueKey('book_grid'),
                    expandedSeriesId: expandedSeriesId,
                    gridItemSlot:
                        (context, item, innerBuilder, {onTapOverride}) {
                          final focusId = item.id;

                          void action(BuildContext ctx) {
                            final RenderBox? itemBox =
                                ctx.findRenderObject() as RenderBox?;
                            if (itemBox != null) {
                              final itemGlobal = itemBox.localToGlobal(
                                Offset.zero,
                              );
                              BookService.instance.lastHeroRect =
                                  itemGlobal & itemBox.size;
                              BookService.instance.lastHeroItem = item;
                            }

                            onTapOverride != null
                                ? onTapOverride()
                                : BookCallback.onBookPosterTap(
                                    ctx,
                                    item,
                                    expandedSeriesId,
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
                                    () => action(ctx),
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
