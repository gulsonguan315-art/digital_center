import 'package:flutter/material.dart';
import '../../../core/data/data_manager.dart';
import '../../../core/data/models/book_data.dart';
import '../../../core/data/repositories/book_repository.dart';
import '../../../core/log/log.dart';
import '../../overlay/book/book_reader_controller.dart';

enum BookLoadState { idle, loading, loaded, error }

/// 📚 图书服务中心 (Application-level Book Service)
class BookService extends ChangeNotifier {
  static final BookService instance = BookService._();
  BookService._();

  final BookReaderController readerController = BookReaderController();

  String _selectedLibrary = '';
  String get selectedLibrary => _selectedLibrary;

  String _selectedLibraryAlias = '';
  String get selectedLibraryAlias => _selectedLibraryAlias;

  List<BookItem> _items = [];
  List<BookItem> get items => _items;

  BookLoadState _loadState = BookLoadState.idle;
  BookLoadState get loadState => _loadState;

  Rect? lastHeroRect;
  BookItem? lastHeroItem;

  final Map<String, List<BookItem>> _seriesChildrenCache = {};
  Map<String, List<BookItem>> get seriesChildrenCache => _seriesChildrenCache;

  List<BookLibrary> _libraries = [];
  List<BookLibrary> get libraries => _libraries;

  String _baseUrl = '';
  String _token = '';

  Future<void> fetchLibraries() async {
    final settings = await DataManager.instance.getUserSettings();
    _baseUrl = settings.api.absBaseUrl;
    _token = settings.api.absApiKey;

    _libraries = await BookRepository.instance.fetchLibraries();
    notifyListeners();
  }

  void setLibrary(String libraryId) async {
    if (_selectedLibrary == libraryId && _loadState == BookLoadState.loaded) return;
    _selectedLibrary = libraryId;
    _loadState = BookLoadState.loading;
    _items = [];
    notifyListeners();

    try {
      _items = await BookRepository.instance.fetchLibraryItems(libraryId, collapseSeries: true);
      _loadState = BookLoadState.loaded;
    } catch (e) {
      _loadState = BookLoadState.error;
    }
    notifyListeners();
  }

  void setLibraryByAlias(String alias) async {
    if (_libraries.isEmpty) {
      await fetchLibraries();
    }
    String libName;
    switch (alias) {
      case 'sci_fi': libName = '科幻'; break;
      case 'Humanities': libName = '人文'; break;
      case 'Power_Fantasy': libName = '爽文'; break;
      default: return;
    }
    final lib = _libraries.where((l) => l.name == libName).firstOrNull;
    if (lib != null) {
      _selectedLibraryAlias = alias;
      setLibrary(lib.id);
    }
  }

  /// 获取封面同步返回
  String getCoverArtUrl(String itemId) {
    if (_baseUrl.isEmpty || _token.isEmpty) return '';
    return '$_baseUrl/api/items/$itemId/cover?token=$_token';
  }

  Future<void> ensureSeriesLoaded(String seriesId, List<String> libraryItemIds) async {
    if (_seriesChildrenCache.containsKey(seriesId)) return;
    
    // 异步拉取每个内部图册的详细信息
    try {
      final futures = libraryItemIds.map((id) => BookRepository.instance.fetchItem(id));
      final items = await Future.wait(futures);
      _seriesChildrenCache[seriesId] = items.whereType<BookItem>().toList();
    } catch (e) {
      _seriesChildrenCache[seriesId] = [];
    }
    
    notifyListeners();
  }

  /// 📖 打开电子书
  Future<void> openBook(BookItem item) async {
    readerController.setLoading(true);
    try {
      final bytes = await BookRepository.instance.downloadItemBytes(item.id);
      if (bytes != null) {
        Log.d(LogGroup.book, '✅ [Book] 书籍下载成功: ${item.id}, size: ${bytes.length}');
        await readerController.loadEpubBytes(bytes);
      } else {
        Log.d(LogGroup.book, '❌ [Book] 书籍下载失败: ${item.id}');
        readerController.setLoading(false);
      }
    } catch (e) {
      Log.d(LogGroup.book, '❌ [Book] 打开书籍出现异常: $e');
      readerController.setLoading(false);
    }
  }
}
