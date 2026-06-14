import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:epub_plus/epub_plus.dart';
import 'package:archive/archive.dart';
import '../../../../core/log/log.dart';

class BookChapter {
  final String title;
  final String htmlContent;

  BookChapter(this.title, this.htmlContent);
}

class BookReaderController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  
  EpubBook? _currentBook;
  final List<BookChapter> _chapters = [];
  int _currentChapterIndex = 0;
  bool _isLoading = false;

  List<BookChapter> get chapters => _chapters;
  int get currentChapterIndex => _currentChapterIndex;
  bool get isLoading => _isLoading;

  BookChapter? get currentChapter {
    if (_chapters.isEmpty || _currentChapterIndex < 0 || _currentChapterIndex >= _chapters.length) {
      return null;
    }
    return _chapters[_currentChapterIndex];
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadEpubBytes(List<int> bytes) async {
    setLoading(true);
    try {
      List<int> actualEpubBytes = bytes;
      
      try {
        final archive = ZipDecoder().decodeBytes(bytes);
        bool hasContainer = archive.any((f) => f.name == 'META-INF/container.xml');
        if (!hasContainer) {
          Log.d(LogGroup.book, '⚠️ [Book] 检测到下载的不是直接的 EPUB，尝试从压缩包中提取...');
          for (var file in archive) {
            if (file.name.toLowerCase().endsWith('.epub')) {
              Log.d(LogGroup.book, '✅ [Book] 成功提取压缩包内的实体文件: ${file.name}');
              actualEpubBytes = file.content as List<int>;
              break;
            }
          }
        }
      } catch (_) {
      }

      _currentBook = await EpubReader.readBook(actualEpubBytes);
      _chapters.clear();
      
      if (_currentBook?.chapters != null) {
        _extractChapters(_currentBook!.chapters);
      }
      
      Log.d(LogGroup.book, '✅ [Book] EPUB 解析成功: chapters count = ${_chapters.length}');
      _currentChapterIndex = 0;
    } catch (e) {
      Log.d(LogGroup.book, '❌ [Book] EPUB 解析失败: $e');
    } finally {
      setLoading(false);
    }
  }

  void _extractChapters(List<EpubChapter> epubChapters) {
    for (var chapter in epubChapters) {
      if (chapter.title != null && chapter.htmlContent != null) {
        _chapters.add(BookChapter(chapter.title!, chapter.htmlContent!));
      }
      if (chapter.subChapters.isNotEmpty) {
        _extractChapters(chapter.subChapters);
      }
    }
  }

  void _resetScroll() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  void nextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      _currentChapterIndex++;
      _resetScroll();
      notifyListeners();
    }
  }

  void previousChapter() {
    if (_currentChapterIndex > 0) {
      _currentChapterIndex--;
      _resetScroll();
      notifyListeners();
    }
  }

  void jumpToChapter(int index) {
    if (index >= 0 && index < _chapters.length) {
      _currentChapterIndex = index;
      _resetScroll();
      notifyListeners();
    }
  }
}