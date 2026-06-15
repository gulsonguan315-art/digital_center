import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_manager.dart';
import '../../../../core/control/device_manager/device_manager.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../resident/book/book_model.dart';
import '../../resident/book/book_service.dart';
import 'book_reader_renderer.dart';
import 'views_components/book_chapter_panel.dart';
import 'views_components/book_control_panel.dart';
import 'views_components/book_settings_panel.dart';
import 'views_components/book_reader_header.dart';

class BookReaderView extends StatefulWidget {
  const BookReaderView({super.key});

  @override
  State<BookReaderView> createState() => _BookReaderViewState();
}

class _BookReaderViewState extends State<BookReaderView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _handleLocalInput(InputSignal signal) {
    final isBottomMenuVisible = SuperFocusManager.instance.state.checkIsActive('book_control');
    final isChapterPanelVisible = SuperFocusManager.instance.state.checkIsActive('book_menu');
    final isSettingsPanelVisible = SuperFocusManager.instance.state.checkIsActive('book_settings');

    if (isBottomMenuVisible || isChapterPanelVisible || isSettingsPanelVisible) {
      if (signal == InputSignal.menu || signal == InputSignal.back) {
        FocusAPI.dispatchBackCommand();
        return true;
      }
      return false; // let overlays handle focus movement internally
    } else {
      switch (signal) {
        case InputSignal.down:
          final controller = BookService.instance.readerController;
          final sc = controller.scrollController;
          if (sc.hasClients) {
            final fontSize = controller.fontSize;
            final lineHeight = controller.lineHeight;
            final double scrollAmount = fontSize * lineHeight * controller.scrollLines; 
            final target = (sc.offset + scrollAmount).clamp(0.0, sc.position.maxScrollExtent);
            sc.animateTo(target, duration: const Duration(milliseconds: 150), curve: Curves.easeInOut);
          }
          return true;
        case InputSignal.up:
          final controller = BookService.instance.readerController;
          final sc = controller.scrollController;
          if (sc.hasClients) {
            final fontSize = controller.fontSize;
            final lineHeight = controller.lineHeight;
            final double scrollAmount = fontSize * lineHeight * controller.scrollLines; 
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
          // Toggle bottom menu
          FocusAPI.dispatchAction(BookModel.bookOverlayId, BookModel.bookAirNodeId);
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
      child: Builder(
        builder: (roomContext) {
          final isBottomMenuVisible = roomContext.useIsActive('book_control');
          final isChapterPanelVisible = roomContext.useIsActive('book_menu');
          final isSettingsPanelVisible = roomContext.useIsActive('book_settings');
          
          final hasActiveOverlay = isBottomMenuVisible || isChapterPanelVisible || isSettingsPanelVisible;

          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: colors.surface,
                  child: Column(
                    children: [
                      const BookReaderHeader(),
                      const Expanded(
                        child: BookReaderRenderer(),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 约束保护：空气节点置于阅读正文之上、控制面板之下，既可接收空白处点击，又不会遮挡控制面板
              const Positioned.fill(child: SuperFocusAirNode()),
              
              if (hasActiveOverlay) ...[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      FocusAPI.dispatchBackCommand();
                    },
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.15), // 稍微调暗，提升对比度
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              
              // Bottom control panel
              if (isBottomMenuVisible)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: const BookControlPanel(),
                ),

              // Left chapter directory panel
              if (isChapterPanelVisible)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: BookChapterPanel(
                    onChapterSelected: (index) {
                      BookService.instance.readerController.jumpToChapter(index);
                      FocusAPI.dispatchAction(BookModel.bookOverlayId, BookModel.bookAirNodeId); // close and return
                    },
                  ),
                ),

              // Right settings panel
              if (isSettingsPanelVisible)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: const BookSettingsPanel(),
                ),
            ],
          );
        },
      ),
    );
  }
}