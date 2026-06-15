import 'package:flutter/material.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../resident/book/book_service.dart';

class BookReaderHeader extends StatelessWidget {
  const BookReaderHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.useTheme().colors;

    return ListenableBuilder(
      listenable: BookService.instance.readerController,
      builder: (context, _) {
        final controller = BookService.instance.readerController;
        final chapter = controller.currentChapter;

        if (chapter == null) {
          return const SizedBox.shrink();
        }

        // 动态主题配色
        Color textPrimaryColor = colors.textPrimary;
        Color textSecondaryColor = colors.textSecondary;
        Color borderColor = colors.border;

        final readerTheme = controller.themeMode;
        if (readerTheme == 'parchment') {
          textPrimaryColor = const Color(0xFF3E2723);
          textSecondaryColor = const Color(0xFF795548);
          borderColor = const Color(0xFFD7CCC8);
        } else if (readerTheme == 'eye_care') {
          textPrimaryColor = const Color(0xFF1B5E20);
          textSecondaryColor = const Color(0xFF4CAF50);
          borderColor = const Color(0xFFA5D6A7);
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: textPrimaryColor.withValues(alpha: 0.2),
            border: Border(
              bottom: BorderSide(
                color: borderColor.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 12.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (chapter.ancestors.isNotEmpty) ...[
                    Text(
                      chapter.ancestors.join(' · '),
                      style: TextStyle(
                        fontFamily: 'LeMiHuiYuan',
                        fontSize: 16,
                        color: textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    chapter.title,
                    style: TextStyle(
                      fontFamily: 'LeMiHuiYuan',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
