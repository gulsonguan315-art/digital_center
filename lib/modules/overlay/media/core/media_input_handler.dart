import '../../../../core/control/superfocus/focus_api.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_manager.dart';
import '../../../../core/control/device_manager/device_manager.dart';
import 'player_engine.dart';

/// 纯粹的输入拦截与分发器（瞎子模式）
/// 它只关心两件事：当前的焦点弹窗状态，以及按下按键后该执行哪个动作。
/// 它不关心播放器内部逻辑，所有的播放与进度控制直接交由 PlayerEngine 处理，切集逻辑由上层提供回调。
class MediaInputHandler {
  final PlayerEngine playerEngine;

  MediaInputHandler({required this.playerEngine});

  bool handleLocalInput(InputSignal signal) {
    final showMenu = SuperFocusManager.instance.state.checkIsActive('media_menu');
    final showHomeConfirm = SuperFocusManager.instance.state.checkIsActive('media_home_confirm');

    // 拦截层：如果当前有菜单或弹窗
    if (showMenu || showHomeConfirm) {
      if (signal == InputSignal.menu || signal == InputSignal.back) {
        FocusAPI.dispatchBackCommand();
        if (showHomeConfirm) {
          playerEngine.resumeIfWasPlayingBeforeSeek();
        }
        return true;
      }
      return false; // 允许菜单项/弹窗内正常使用方向键与确认键
    } 
    
    // 执行层：无遮挡时的普通按键映射
    switch (signal) {
      case InputSignal.menu:
        FocusAPI.dispatchAction('media_overlay', 'media_overlay_air_node');
        return true;
      case InputSignal.confirm:
        playerEngine.playOrPause();
        return true;
      case InputSignal.left:
        playerEngine.seekBackward();
        return true;
      case InputSignal.right:
        playerEngine.seekForward();
        return true;
      case InputSignal.home:
        playerEngine.pauseForDialog();
        FocusAPI.dispatchAction('media_overlay', 'media_home_trigger');
        return true;
      case InputSignal.up:
        playerEngine.switchEpisode(-1);
        return true;
      case InputSignal.down:
        playerEngine.switchEpisode(1);
        return true;
      case InputSignal.volumeUp:
      case InputSignal.volumeDown:
      case InputSignal.back:
        return false; // 放行给全局处理（回退或调整全局音量）
    }
  }
}
