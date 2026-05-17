import '../../../core/control/superfocus/focus_api.dart';
import 'sidebar_model.dart';

/// 侧边栏交互回调逻辑 (Action Layer)
class SidebarCallback {
  /// 处理菜单项导航
  static void onNavigate(String id, {String? parentRoomId}) {
    FocusAPI.dispatchAction(parentRoomId ?? SidebarModel.sidebarRoomId, id);
  }

  /// 处理退出/电源逻辑
  static void onExit() {
    FocusAPI.dispatchAction(SidebarModel.sidebarRoomId, SidebarModel.exitId);
  }
}
