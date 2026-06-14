import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_widgets.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../resident/book/book_service.dart';
import '../../../resident/book/book_model.dart';

/// 📖 图书章节侧边栏面板 (Book Chapter Panel)
///
/// 从主阅读视图分离出来的独立组件，负责渲染章节目录列表。
/// 通过 [onChapterSelected] 回调通知父层跳转并关闭。
class BookChapterPanel extends StatelessWidget {
  /// 选中章节后的回调，传回章节索引
  final void Function(int index) onChapterSelected;

  const BookChapterPanel({super.key, required this.onChapterSelected});

  @override
  Widget build(BuildContext context) {
    final colors = context.useTheme().colors;

    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(
            color: colors.border,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
                  id: BookModel.bookMenuId,
                  child: ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.0,
                        ),
                        child: SuperFocusItem(
                          id: 'book_chapter_$index',
                          onPressed: () => onChapterSelected(index),
                          builder: (context, hasFocus) {
                            return Container(
                              color: hasFocus
                                  ? colors.accent.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Text(
                                chapter.title,
                                style: TextStyle(
                                  color: hasFocus
                                      ? colors.accent
                                      : colors.textPrimary,
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
    );
  }
}
