import 'dart:async';
import 'package:flutter/material.dart';

import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/control/superfocus/interaction_manager.dart';
import '../../../core/control/device_manager/device_manager.dart';
import '../../../core/layout/grid/grid.dart';

import '../../../../core/engine/theme/theme_api.dart';

import 'core/media_engine_controller.dart';
import 'core/media_seek_controller.dart';
import 'views_components/media_home_confirm_dialog.dart';
import 'views_components/media_immersive_control_panel.dart';
import 'views_components/media_immersive_hud.dart';

class MediaImmersiveOverlay extends StatefulWidget {
  final String itemId;

  const MediaImmersiveOverlay({super.key, required this.itemId});

  @override
  State<MediaImmersiveOverlay> createState() => _MediaImmersiveOverlayState();
}

class _MediaImmersiveOverlayState extends State<MediaImmersiveOverlay> {
  final StreamController<String> _interactionStreamController =
      StreamController<String>.broadcast();

  late final MediaEngineController _engineController;
  late final MediaSeekController _seekController;

  @override
  void initState() {
    super.initState();
    _engineController = MediaEngineController(
      interactionStreamController: _interactionStreamController,
    );
    _engineController.init(widget.itemId);

    _seekController = MediaSeekController(
      _engineController.player,
      _interactionStreamController,
    );
  }

  @override
  void dispose() {
    _seekController.dispose();
    _engineController.dispose();
    _interactionStreamController.close();
    super.dispose();
  }

  bool _handleLocalInput(InputSignal signal) {
    final showMenu = SuperFocusManager.instance.state.checkIsActive(
      'media_menu',
    );
    final showHomeConfirm = SuperFocusManager.instance.state.checkIsActive(
      'media_home_confirm',
    );

    if (showMenu || showHomeConfirm) {
      if (signal == InputSignal.menu || signal == InputSignal.back) {
        FocusAPI.dispatchBackCommand();
        if (showHomeConfirm &&
            !_engineController.player.state.playing &&
            _seekController.wasPlayingBeforeSeek) {
          _engineController.player.play(); // 如果弹窗取消，恢复播放
        }
        return true;
      }
      return false; // 允许菜单项/弹窗内正常使用方向键与确认键
    } else {
      switch (signal) {
        case InputSignal.menu:
          // 动作触发焦点从空气节点路由转移至菜单 media_menu
          FocusAPI.dispatchAction('media_overlay', 'media_overlay_air_node');
          return true;
        case InputSignal.confirm:
          // Enter/确认键 暂停或播放
          _engineController.player.playOrPause();
          return true;
        case InputSignal.left:
          // 左键快退 10 秒 / 长按 30 秒
          _seekController.seekRelative(InputSignal.left);
          return true;
        case InputSignal.right:
          // 右键快进 10 秒 / 长按 30 秒
          _seekController.seekRelative(InputSignal.right);
          return true;
        case InputSignal.home:
          // 暂停播放，并触发拓扑跳转，显示自定义的焦点弹窗
          _seekController.wasPlayingBeforeSeek =
              _engineController.player.state.playing;
          if (_seekController.wasPlayingBeforeSeek)
            _engineController.player.pause();
          FocusAPI.dispatchAction('media_overlay', 'media_home_trigger');
          return true;
        case InputSignal.volumeUp:
        case InputSignal.volumeDown:
        case InputSignal.back:
          return false; // 放行给全局处理（回退或调整全局音量）
        default:
          return true; // 空气节点吞噬其他一切操作，防止焦点逃逸
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.appBackground,
      child: Scaffold(
        backgroundColor: Colors.black, // 设置为纯黑背景
        body: SuperFocusRoom(
          id: 'media_overlay',
          child: InputInterceptor(
            onSignal: _handleLocalInput,
            child: Builder(
              builder: (roomContext) {
                final showMenu = roomContext.useIsActive('media_menu');
                final scope = roomContext
                    .dependOnInheritedWidgetOfExactType<RoomScope>();
                final isIntendingToEnter =
                    SuperFocusManager.instance.intentionRoomId.value ==
                    'media_overlay';

                if (scope != null && !scope.isActive && !isIntendingToEnter) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                  });
                }

                return Stack(
                  children: [
                    // 真正的播放器组件
                    Positioned.fill(
                      child: Video(
                        controller: _engineController.videoController,
                        controls: NoVideoControls, // 禁用默认控制面板
                      ),
                    ),

                    // 点击空白处关闭菜单或退出
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (showMenu ||
                              roomContext.useIsActive('media_home_confirm')) {
                            FocusAPI.dispatchBackCommand();
                            if (roomContext.useIsActive('media_home_confirm') &&
                                !_engineController.player.state.playing &&
                                _seekController.wasPlayingBeforeSeek) {
                              _engineController.player.play();
                            }
                          } else {
                            if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // 抽离出的 HUD (暂停提醒、进度条、顶部时间)
                    MediaImmersiveHud(
                      player: _engineController.player,
                      interactionStream: _interactionStreamController.stream,
                      virtualPositionNotifier:
                          _seekController.virtualPositionNotifier,
                    ),

                    // 约束保护：强制空气节点用 Positioned.fill 包裹，且常驻以防焦点退回父容器
                    const Positioned.fill(child: SuperFocusAirNode()),

                    // 左侧悬浮控制菜单
                    if (showMenu)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.only(
                            left: GridContext.fromViewport(
                              MediaQuery.sizeOf(context),
                            ).pageInset,
                          ),
                          alignment: Alignment.centerLeft,
                          child: const MediaImmersiveControlPanel(),
                        ),
                      ),

                    // 居中显示的退出确认弹窗
                    if (roomContext.useIsActive('media_home_confirm'))
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: MediaHomeConfirmDialog(
                            onCancel: () {
                              if (_seekController.wasPlayingBeforeSeek)
                                _engineController.player.play();
                            },
                            onConfirm:
                                () {}, // FocusAPI.dispatchHomeCommand() 已经在 Dialog 里调用了
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
