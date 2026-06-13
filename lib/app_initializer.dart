import 'modules/resident/dashboard/dashboard_room.dart';
import 'modules/resident/exit/exit_page_room.dart';
import 'modules/resident/book/book_page/book_room.dart';
import 'modules/resident/media/media_page/media_room.dart';
import 'modules/resident/music/music_room.dart';
import 'modules/resident/settings/setting_page_room.dart';
import 'modules/resident/test/test_page_room.dart';
import 'modules/widgets/poetry/poetry_overlay_room.dart';

/// 📂 应用层总组装与初始化 (Composition Root)
/// 负责在启动时触发所有房间的自注册，使得 core 层不依赖具体业务模块。
class AppInitializer {
  static void init() {
    DashboardRoom.register();
    MediaRoom.register();
    BookRoom.register();
    MusicRoom.register();
    PoetryOverlayRoom.register();
    SettingPageRoom.register();
    TestPageRoom.register();
    ExitPageRoom.register();
  }
}
