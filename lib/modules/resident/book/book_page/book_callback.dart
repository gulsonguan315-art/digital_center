import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/data/models/book_data.dart';
import '../book_model.dart';
import '../book_service.dart';

class BookCallback {
  static void onBookPosterTap(
    BuildContext context,
    BookItem item,
    String? expandedSeriesId,
  ) {
    if (item.isSeries) {
      if (expandedSeriesId == item.id) {
        // 关闭展开
        FocusAPI.dispatchBackCommand();
      } else {
        // 展开合集
        BookService.instance.ensureSeriesLoaded(item.id, item.libraryItemIds);
        FocusAPI.dispatchAction(BookModel.bookPageId, 'bookExpand_${item.id}');
      }
    } else {
      // 单本图书，可调用阅读器
      // 同时通知 Service 开始加载这本电子书
      BookService.instance.openBook(item);

      final sourceRoom = expandedSeriesId != null
          ? 'bookExpand_$expandedSeriesId'
          : BookModel.bookPageId;
      FocusAPI.dispatchAction(sourceRoom, BookModel.bookOverlayId);
    }
  }
}
