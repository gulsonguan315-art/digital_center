import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/control/superfocus/focus_widgets.dart';
import '../../../../core/control/device_manager/device_manager.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../resident/book/book_model.dart';
import '../../resident/book/book_service.dart';
import 'book_reader_renderer.dart';
import 'views_components/book_chapter_panel.dart';

class BookReaderView extends StatefulWidget {
  const BookReaderView({super.key});

  @override
  State<BookReaderView> createState() => _BookReaderViewState();
}

class _BookReaderViewState extends State<BookReaderView> {
  bool _isMenuVisible = false;

  void _toggleMenu() {
    setState(() {
      _isMenuVisible = !_isMenuVisible;
    });
    if (_isMenuVisible) {
      FocusAPI.dispatchAction(BookModel.bookOverlayId, BookModel.bookAirNodeId);
    } else {
      FocusAPI.dispatchBackCommand();
    }
  }

  bool _handleLocalInput(InputSignal signal) {
    if (_isMenuVisible) {
      if (signal == InputSignal.menu || signal == InputSignal.back) {
        _toggleMenu();
        return true;
      }
      return false; // let menu items handle up/down/confirm
    } else {
      switch (signal) {
        case InputSignal.down:
          final sc = BookService.instance.readerController.scrollController;
          if (sc.hasClients) {
            // 滚动 3 行：字号 22 * 行高 1.8 * 3
            const double scrollAmount = 22 * 1.8 * 3; 
            final target = (sc.offset + scrollAmount).clamp(0.0, sc.position.maxScrollExtent);
            sc.animateTo(target, duration: const Duration(milliseconds: 150), curve: Curves.easeInOut);
          }
          return true;
        case InputSignal.up:
          final sc = BookService.instance.readerController.scrollController;
          if (sc.hasClients) {
            // 滚动 3 行：字号 22 * 行高 1.8 * 3
            const double scrollAmount = 22 * 1.8 * 3; 
            final target = (sc.offset - scrollAmount).clamp(0.0, sc.position.maxScrollExtent);
            sc.animateTo(target, duration: const Duration(milliseconds: 150), curve: Curves.easeInOut);
          }
          return true;
        case InputSignal.right:
          BookService.instance.readerController.nextChapter();
          return true;
        case InputSignal.left:
          BookService.instance.readerController.previousChapter();
          return true;
        case InputSignal.menu:
          _toggleMenu();
          return true;
        case InputSignal.back:
          FocusAPI.dispatchBackCommand();
          return true;
        default:
          return false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.useTheme().colors;
    
    return InputInterceptor(
      onSignal: _handleLocalInput,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: colors.surface,
              child: const BookReaderRenderer(),
            ),
          ),
          
          if (_isMenuVisible)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: BookChapterPanel(
                onChapterSelected: (index) {
                  BookService.instance.readerController.jumpToChapter(index);
                  _toggleMenu();
                },
              ),
            ),
        ],
      ),
    );
  }
}