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
import '../../../overlay/book/book_reader_room.dart';

/// 📚 图书页面主房间 (Book Room - Composition Root)
class BookRoom extends StatefulWidget {
  final Widget? child;
  const BookRoom({super.key, this.child});

  static const String roomId = BookModel.bookPageId;

  static void register() {
    // 🌟 一并注册所有图书相关合约（对标 MediaRoom.register() 统一注册模式）
    StageRegistry.register(
      StageContract(
        roomId: roomId,
        zone: StageZone.firstFloor_main,
        keepAlive: true,
        builder: (context) => const BookRoom(),
      ),
    );

    BookReaderRoom.registerContract();
  }

  @override
  State<BookRoom> createState() => _BookRoomState();
}

class _BookRoomState extends State<BookRoom> {
  String? _lastExpandedSeriesId;

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

              // StageView 已用 Offstage + TickerMode 包裹非活跃房间，无需激进卸载。
              // 强制 shrink 会销毁内部 FocusNode，破坏传送门弹栈时的焦点记忆。

              // 判断合集展开状态
              String? expandedSeriesId;
              final activeRoom = topology.activeRoom;
              if (activeRoom != null) {
                if (activeRoom.startsWith('bookExpand_')) {
                  expandedSeriesId = activeRoom.replaceFirst('bookExpand_', '');
                  _lastExpandedSeriesId = expandedSeriesId;
                } else if (activeRoom == BookRoom.roomId || !activeRoom.startsWith('book_')) {
                  expandedSeriesId = null;
                  _lastExpandedSeriesId = null;
                } else {
                  expandedSeriesId = _lastExpandedSeriesId;
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
                          final focusId = item.isSeries
                              ? 'series_${item.id}'
                              : 'book_${item.id}';

                          void action(BuildContext ctx) {
                            // 🌟 焦点系统自动抓取游标物理坐标，无需手动计算 Rect
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
