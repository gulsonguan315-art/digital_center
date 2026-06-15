import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_widgets.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../../core/stage/stage_contract.dart';
import '../../../../core/stage/stage_models.dart';
import '../../../../core/stage/stage_registry.dart';
import '../../resident/book/book_model.dart';
import 'book_reader_view.dart';

class BookReaderRoom extends StatefulWidget {
  const BookReaderRoom({super.key});

  /// 注册 book_overlay 的 StageContract。
  /// ⚠️ 由 [BookRoom.register()] 统一调用，请勿在其他地方单独调用。
  static void registerContract() {
    StageRegistry.register(
      StageContract(
        roomId: BookModel.bookOverlayId,
        zone: StageZone.thirdFloor_overlay,
        keepAlive: false,
        builder: (context) => const BookReaderRoom(),
      ),
    );
  }

  @override
  State<BookReaderRoom> createState() => _BookReaderRoomState();
}

class _BookReaderRoomState extends State<BookReaderRoom> {
  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.appBackground,
      child: Scaffold(
        backgroundColor: Colors.black, // 纯黑底色，和 Media 保持一致
        body: SuperFocusRoom(
          id: BookModel.bookOverlayId,
          child: const BookReaderView(),
        ),
      ),
    );
  }
}
