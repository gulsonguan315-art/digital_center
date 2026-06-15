import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:epub_plus/epub_plus.dart' hide Image;
import '../../../../core/engine/theme/theme_api.dart';
import '../../resident/book/book_service.dart';

abstract class EpubElement {}

class EpubTextElement extends EpubElement {
  final String text;
  EpubTextElement(this.text);
}

class EpubImageElement extends EpubElement {
  final String src;
  EpubImageElement(this.src);
}

class BookReaderRenderer extends StatelessWidget {
  const BookReaderRenderer({super.key});

  String _cleanHtmlText(String html) {
    // 0. 彻底移除整个 <head> 头部区域（包括其中的 <title>、<style> 等所有内容）
    String text = html.replaceAll(
      RegExp(r'<head\b[^>]*>([\s\S]*?)</head>', caseSensitive: false),
      '',
    );

    // 1. 移除 HTML 源码中的原生换行（在 HTML 中只等价于空格）
    text = text.replaceAll(RegExp(r'\r?\n'), ' ');

    // 1.5. 移除所有的超链接注释标签及内容 (如 <a href="...">1</a>)
    text = text.replaceAll(
      RegExp(
        r'<a\s+[^>]*>(?:(?:注|注释|note|footnote)?\s*[\[【（(]*\d+[\]】）)]*|\*+|[a-zA-Z])</a>',
        caseSensitive: false,
      ),
      '',
    );

    // 2. 将块级元素结束标签或换行标签替换为我们的结构化换行
    text = text.replaceAll(
      RegExp(
        r'</p>|<br\s*/?>|</h1>|</h2>|</h3>|</h4>|</h5>|</h6>|</div>|</li>',
        caseSensitive: false,
      ),
      '\n\n',
    );

    // 3. 剥离所有剩余的 HTML 标签
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // 4. 解析常用的 HTML 实体
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&mdash;', '—')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rsquo;', '’');

    // 5. 压缩水平空白符
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    // 6. 压缩垂直空白符，确保最多只有两个换行符
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n').trim();

    // 7. 增加中文首行缩进排版（全角空格）
    if (text.isNotEmpty) {
      text = '　　$text'.replaceAll('\n\n', '\n\n　　');
    }
    return text;
  }

  List<EpubElement> _parseHtmlToElements(String html) {
    final List<EpubElement> elements = [];
    final imgRegex = RegExp(r'<(img|image)\b[^>]*>', caseSensitive: false);

    int currentIndex = 0;
    for (final match in imgRegex.allMatches(html)) {
      if (match.start > currentIndex) {
        final textSegment = html.substring(currentIndex, match.start);
        final cleanedText = _cleanHtmlText(textSegment);
        if (cleanedText.isNotEmpty) {
          elements.add(EpubTextElement(cleanedText));
        }
      }

      final imgTag = match.group(0)!;
      final srcMatch = RegExp(r'(src|href)\s*=\s*["' "'" r']([^"' "'" r']+)["' "'" r']', caseSensitive: false).firstMatch(imgTag);
      if (srcMatch != null) {
        final src = srcMatch.group(2)!;
        elements.add(EpubImageElement(src));
      }

      currentIndex = match.end;
    }

    if (currentIndex < html.length) {
      final textSegment = html.substring(currentIndex);
      final cleanedText = _cleanHtmlText(textSegment);
      if (cleanedText.isNotEmpty) {
        elements.add(EpubTextElement(cleanedText));
      }
    }

    return elements;
  }

  Widget _buildEpubImage(String src, EpubBook? book, RoleColors colors) {
    if (book == null) return const SizedBox.shrink();
    final content = book.content;
    if (content == null) return const SizedBox.shrink();
    final images = content.images;

    final cleanSrc = src.split('/').last.toLowerCase();
    String? matchKey;
    for (final key in images.keys) {
      if (key.split('/').last.toLowerCase() == cleanSrc) {
        matchKey = key;
        break;
      }
    }

    if (matchKey == null) {
      return const SizedBox.shrink();
    }

    final imageFile = images[matchKey];
    if (imageFile == null) return const SizedBox.shrink();
    final imageContent = imageFile.content;
    if (imageContent == null || imageContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.memory(
            Uint8List.fromList(imageContent),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '图片加载失败',
                  style: TextStyle(color: Colors.red),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.useTheme().colors;

    return ListenableBuilder(
      listenable: BookService.instance.readerController,
      builder: (context, _) {
        final controller = BookService.instance.readerController;

        if (controller.isLoading) {
          return Center(child: CircularProgressIndicator(color: colors.accent));
        }

        final chapter = controller.currentChapter;
        if (chapter == null) {
          return Center(
            child: Text(
              '没有可渲染的内容',
              style: TextStyle(color: colors.textSecondary),
            ),
          );
        }

        final book = controller.currentBook;
        final elements = _parseHtmlToElements(chapter.htmlContent);

        // 动态主题配色
        Color surfaceColor = colors.surface;
        Color textPrimaryColor = colors.textPrimary;

        final readerTheme = controller.themeMode;
        if (readerTheme == 'parchment') {
          surfaceColor = const Color(0xFFF4ECD8);
          textPrimaryColor = const Color(0xFF3E2723);
        } else if (readerTheme == 'eye_care') {
          surfaceColor = const Color(0xFFCCE8CF); // 经典的豆沙绿/护眼绿
          textPrimaryColor = const Color(0xFF1B5E20);
        }

        return Container(
          color: surfaceColor,
          child: SingleChildScrollView(
            controller: controller.scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 48.0,
              vertical: 24.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: elements.map((element) {
                    if (element is EpubTextElement) {
                      return Text(
                        element.text,
                        style: TextStyle(
                          fontFamily: 'LeMiHuiYuan',
                          fontSize: controller.fontSize,
                          fontWeight: controller.fontWeight,
                          height: controller.lineHeight,
                          color: textPrimaryColor.withValues(alpha: 0.9),
                        ),
                      );
                    } else if (element is EpubImageElement) {
                      return _buildEpubImage(element.src, book, colors);
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
