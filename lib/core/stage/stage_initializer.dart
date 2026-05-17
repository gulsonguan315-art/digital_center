import '../../modules/resident/dashboard/dashboard_page.dart';
import '../../modules/resident/settings/setting_page.dart';
import '../../modules/resident/test/test_page.dart';
import '../../modules/widgets/poetry/poetry_overlay_room.dart'; // 🌟 引入诗词沉浸Overlay
import 'stage_contract.dart';
import 'stage_models.dart';
import 'stage_registry.dart';

/// 舞台初始化器
class StageInitializer {
  static void init() {
    StageRegistry.register(
      StageContract(
        roomId: DashboardRoom.roomId,
        zone: StageZone.main,
        keepAlive: true,
        builder: (context) => const DashboardRoom(),
      ),
    );

    StageRegistry.register(
      StageContract(
        roomId: 'poetry_overlay',
        zone: StageZone.overlay, // 🌟 注册全屏覆盖Overlay防区
        keepAlive: false,
        builder: (context) => const PoetryOverlayRoom(),
      ),
    );

    StageRegistry.register(
      StageContract(
        roomId: SettingPageRoom.roomId,
        zone: StageZone.main,
        keepAlive: false,
        builder: (context) => const SettingPageRoom(),
      ),
    );

    StageRegistry.register(
      StageContract(
        roomId: TestPageRoom.roomId,
        zone: StageZone.main,
        keepAlive: false,
        builder: (context) => const TestPageRoom(),
      ),
    );
  }
}
