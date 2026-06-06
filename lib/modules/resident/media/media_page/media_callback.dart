import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/data/models/media_item.dart';
import '../media_model.dart';
import '../media_service.dart';

/// 📂 影视模块交互回调中心 (Media Callback Coordinator)
/// 
/// 负责集中处理影视模块内的所有业务点击和路由分发逻辑。
/// 实现了 UI 视图层与跳转逻辑的完全解耦。
class MediaCallback {
  /// 处理主海报墙上的点击（包含合集的展开/收起，或进入详情页）
  static void onMediaPosterTap(MediaItem item, String? currentExpandedId) {
    if (item.jellyfinType == 'BoxSet') {
      if (currentExpandedId == item.id) {
        // 如果当前已经展开了该合集，再次点击时触发返回逻辑关闭子房间
        FocusAPI.dispatchBackCommand();
      } else {
        MediaService.instance.ensureBoxSetLoaded(item.id);
        FocusAPI.dispatchAction(MediaModel.mediaPageId, 'mediaExpand_${item.id}');
      }
    } else {
      _routeToDetail(MediaModel.mediaPageId, item);
    }
  }

  /// 处理合集展开区域内部海报的点击（直接进入详情页）
  static void onBoxSetChildTap(MediaItem childItem, String boxSetId) {
    _routeToDetail('mediaExpand_$boxSetId', childItem);
  }

  /// 通用的详情页路由分发：根据数据类型智能分配不同的详情页组件
  static void _routeToDetail(String sourceRoomId, MediaItem item) {
    final isSeries = item.jellyfinType == 'Series';
    final prefix = isSeries ? 'seriesDetail_' : 'movieDetail_';

    FocusAPI.dispatchAction(sourceRoomId, '$prefix${item.id}', asTerminalRoom: true);
  }
}
