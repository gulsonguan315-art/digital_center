import 'package:flutter/material.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../resident/book/book_service.dart';

class BookReaderRenderer extends StatelessWidget {
  const BookReaderRenderer({super.key});

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
        
        // 1. 移除 HTML 源码中的原生换行（在 HTML 中只等价于空格）
        String text = chapter.htmlContent.replaceAll(RegExp(r'\r?\n'), ' ');

        // 1.5. 移除所有的超链接注释标签及内容 (如 <a href="...">1</a>, [2], 注3 等)
        // 使用精确的正则表达式，只过滤数字、星号或单字母等脚注格式，避免误删正常的目录超链接
        text = text.replaceAll(
          RegExp(
            r'<a\s+[^>]*>(?:(?:注|注释|note|footnote)?\s*[\[【（(]*\d+[\]】）)]*|\*+|[a-zA-Z])</a>',
            caseSensitive: false,
          ),
          '',
        );

        // 2. 将块级元素结束标签或换行标签替换为我们的结构化换行
        text = text.replaceAll(RegExp(r'</p>|<br\s*/?>|</h1>|</h2>|</h3>|</h4>|</h5>|</h6>|</div>|</li>', caseSensitive: false), '\n\n');

        // 3. 剥离所有剩余的 HTML 标签
        text = text.replaceAll(RegExp(r'<[^>]*>'), '');

        // 4. 解析常用的 HTML 实体
        text = text.replaceAll('&nbsp;', ' ')
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
        text = '　　$text'.replaceAll('\n\n', '\n\n　　');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chapter.title,
                style: TextStyle(
                  fontFamily: 'LeMiHuiYuan',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller.scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'LeMiHuiYuan',
                      fontSize: 22, // 稍微加大字号提升阅读体验
                      height: 1.8,  // 行高保持舒适
                      color: colors.textPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}