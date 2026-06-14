import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/control/superfocus/focus_widgets.dart';
import '../../../../core/control/device_manager/device_manager.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../resident/book/book_model.dart';
import '../../resident/book/book_service.dart';
import 'book_reader_renderer.dart';

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
      FocusAPI.dispatchAction(BookModel.bookOverlayId, 'book_menu');
    } else {
      FocusAPI.dispatchAction('book_menu', BookModel.bookOverlayId);
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
              width: 350,
              child: Container(
                color: colors.surface.withValues(alpha: 0.95),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '章节目录',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListenableBuilder(
                        listenable: BookService.instance.readerController,
                        builder: (context, _) {
                          final chapters = BookService.instance.readerController.chapters;
                          if (chapters.isEmpty) {
                            return Center(
                              child: Text(
                                '暂无章节',
                                style: TextStyle(color: colors.textSecondary),
                              ),
                            );
                          }
                          
                          return SuperFocusRoom(
                            id: 'book_menu',
                            child: ListView.builder(
                              itemCount: chapters.length,
                              itemBuilder: (context, index) {
                                final chapter = chapters[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                  child: SuperFocusItem(
                                    id: 'book_chapter_$index',
                                    onPressed: () {
                                      BookService.instance.readerController.jumpToChapter(index);
                                      _toggleMenu();
                                    },
                                    builder: (context, hasFocus) {
                                      return Container(
                                        color: hasFocus ? colors.accent.withValues(alpha: 0.3) : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                        child: Text(
                                          chapter.title,
                                          style: TextStyle(
                                            color: hasFocus ? colors.accent : colors.textPrimary,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}