import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/data/models/book_data.dart';
import '../book_model.dart';

import '../book_service.dart';

class BookCallback {
  static void onBookPosterTap(BuildContext context, BookItem item, String? expandedSeriesId) {
    if (item.isSeries) {
      if (expandedSeriesId == item.id) {
        // 关闭展开
        FocusAPI.dispatchBackCommand();
      } else {
        // 展开合集
        BookService.instance.ensureSeriesLoaded(item.id, item.libraryItemIds);
        FocusAPI.dispatchAction(
          BookModel.bookPageId,
          'bookExpand_${item.id}',
        );
      }
    } else {
      // TODO: 单本图书点击后的处理逻辑
    }
  }
}
