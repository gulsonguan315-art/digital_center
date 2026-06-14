import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:epub_plus/epub_plus.dart';
import 'package:archive/archive.dart';
import '../../../../core/log/log.dart';

import 'package:shared_preferences/shared_preferences.dart';

class BookChapter {
  final String title;
  final String htmlContent;
  final List<String> ancestors;

  BookChapter(this.title, this.htmlContent, {this.ancestors = const []});
}

class _RawChapter {
  final String title;
  final String contentFileName;
  final String anchor;
  final String htmlContent;
  final List<String> ancestors;

  _RawChapter(this.title, this.contentFileName, this.anchor, this.htmlContent, {this.ancestors = const []});
}

class ChapterWithPos {
  final _RawChapter chapter;
  final int pos;
  ChapterWithPos(this.chapter, this.pos);
}

class BookReaderController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  
  EpubBook? _currentBook;
  final List<BookChapter> _chapters = [];
  int _currentChapterIndex = 0;
  bool _isLoading = false;

  // --- Reader Preference Settings ---
  double _fontSize = 20.0;
  double get fontSize => _fontSize;

  int _fontWeightIndex = 0; // 0: Normal, 1: Medium, 2: Bold
  int get fontWeightIndex => _fontWeightIndex;

  double _lineHeight = 1.8;
  double get lineHeight => _lineHeight;

  String _themeMode = 'default'; // 'default', 'parchment', 'eye_care'
  String get themeMode => _themeMode;

  FontWeight get fontWeight {
    return switch (_fontWeightIndex) {
      0 => FontWeight.normal,
      1 => FontWeight.w500,
      2 => FontWeight.bold,
      _ => FontWeight.normal,
    };
  }

  BookReaderController() {
    loadPreferences();
  }

  void loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontSize = prefs.getDouble('book_font_size') ?? 20.0;
      _fontWeightIndex = prefs.getInt('book_font_weight_index') ?? 0;
      _lineHeight = prefs.getDouble('book_line_height') ?? 1.8;
      _themeMode = prefs.getString('book_theme_mode') ?? 'default';
      notifyListeners();
    } catch (_) {}
  }

  EpubBook? get currentBook => _currentBook;
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
    final List<_RawChapter> rawChapters = [];
    _extractRawChapters(epubChapters, rawChapters);

    int i = 0;
    while (i < rawChapters.length) {
      final currentFile = rawChapters[i].contentFileName;
      final List<_RawChapter> group = [];
      while (i < rawChapters.length && rawChapters[i].contentFileName == currentFile) {
        group.add(rawChapters[i]);
        i++;
      }

      final fileHtml = group.first.htmlContent;
      final List<ChapterWithPos> items = [];
      for (final raw in group) {
        final pos = _findAnchorPosition(fileHtml, raw.anchor);
        items.add(ChapterWithPos(raw, pos));
      }

      // 按照在 HTML 源码中的物理位置进行排序，以确保正确的阅读流顺序
      items.sort((a, b) => a.pos.compareTo(b.pos));

      for (int k = 0; k < items.length; k++) {
        final start = (k == 0) ? 0 : items[k].pos;
        final end = (k + 1 < items.length) ? items[k + 1].pos : fileHtml.length;
        final content = fileHtml.substring(start, end);

        if (_hasReadableText(content)) {
          _chapters.add(BookChapter(
            items[k].chapter.title,
            content,
            ancestors: items[k].chapter.ancestors,
          ));
        }
      }
    }
  }

  void _extractRawChapters(List<EpubChapter> epubChapters, List<_RawChapter> list, {List<String> ancestors = const []}) {
    for (var chapter in epubChapters) {
      if (chapter.title != null && chapter.htmlContent != null) {
        list.add(_RawChapter(
          chapter.title!,
          chapter.contentFileName ?? '',
          chapter.anchor ?? '',
          chapter.htmlContent!,
          ancestors: ancestors,
        ));
      }
      if (chapter.subChapters.isNotEmpty) {
        final nextAncestors = [...ancestors];
        if (chapter.title != null) {
          nextAncestors.add(chapter.title!);
        }
        _extractRawChapters(chapter.subChapters, list, ancestors: nextAncestors);
      }
    }
  }

  int _findAnchorPosition(String html, String anchor) {
    if (anchor.isEmpty) return 0;

    final regExp = RegExp(
      'id\\s*=\\s*["\']' + RegExp.escape(anchor) + '["\']|name\\s*=\\s*["\']' + RegExp.escape(anchor) + '["\']',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(html);
    if (match != null) {
      int pos = match.start;
      while (pos > 0 && html[pos] != '<') {
        pos--;
      }
      return pos;
    }

    final idx = html.indexOf(anchor);
    if (idx >= 0) {
      int pos = idx;
      while (pos > 0 && html[pos] != '<') {
        pos--;
      }
      return pos;
    }
    return 0;
  }

  bool _hasReadableText(String html) {
    final text = html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (text.isNotEmpty) return true;
    return html.contains(RegExp(r'<img|<image', caseSensitive: false));
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

  void adjustFontSize(double delta) async {
    _fontSize = (_fontSize + delta).clamp(12.0, 40.0);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('book_font_size', _fontSize);
    } catch (_) {}
  }

  void adjustFontWeight(int delta) async {
    _fontWeightIndex = (_fontWeightIndex + delta).clamp(0, 2);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('book_font_weight_index', _fontWeightIndex);
    } catch (_) {}
  }

  void adjustLineHeight(double delta) async {
    _lineHeight = (_lineHeight + delta).clamp(1.0, 3.0);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('book_line_height', _lineHeight);
    } catch (_) {}
  }

  void setThemeMode(String mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('book_theme_mode', _themeMode);
    } catch (_) {}
  }
}