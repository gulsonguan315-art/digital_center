import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../../core/engine/theme/theme_api.dart';

import 'core/media_immersive_controller.dart';
import 'views_components/media_home_confirm_dialog.dart';
import 'views_components/media_immersive_control_panel.dart';
import 'views_components/media_immersive_hud.dart';
import 'core/media_loading_mask.dart';

class MediaImmersiveOverlay extends StatefulWidget {
  final String itemId;
  final String? mediaType;
  final int startPositionTicks;
  final bool forceStartOver;

  const MediaImmersiveOverlay({
    super.key,
    required this.itemId,
    this.mediaType,
    this.startPositionTicks = 0,
    this.forceStartOver = false,
  });

  @override
  State<MediaImmersiveOverlay> createState() => _MediaImmersiveOverlayState();
}

class _MediaImmersiveOverlayState extends State<MediaImmersiveOverlay> {
  late final MediaImmersiveController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MediaImmersiveController(
      sourceItemId: widget.itemId,
      mediaType: widget.mediaType,
      startPositionTicks: widget.startPositionTicks,
      forceStartOver: widget.forceStartOver,
      onExitRequest: () {
        if (mounted) FocusAPI.dispatchBackCommand();
      },
    );
  }

  @override
  void dispose() {
    // 🌟 只要组件被 Stage 卸载（不管是按了返回，还是被外部强制顶替），立刻上报！
    _controller.stopAndReportAsync();
    _controller.dispose();
    super.dispose();
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
            onSignal: _controller.handleLocalInput,
            child: Builder(
              builder: (roomContext) {
                final showMenu = roomContext.useIsActive('media_menu');

                return Stack(
                  children: [
                    // 等待引擎初始化完成再挂载 Video 和 HUD
                    ValueListenableBuilder<PlaybackPhase>(
                      valueListenable: _controller.playbackPhase,
                      builder: (context, phase, _) {
                        if (phase.index < PlaybackPhase.buildingEngine.index)
                          return const SizedBox.shrink();
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Video(
                                controller:
                                    _controller.playerEngine.videoController,
                                controls: NoVideoControls, // 禁用默认控制面板
                              ),
                            ),
                            // 抽离出的 HUD (暂停提醒、进度条、顶部时间)，外包一层监听 Id 变化
                            ValueListenableBuilder<String>(
                              valueListenable:
                                  _controller.currentItemIdNotifier,
                              builder: (context, currentId, child) {
                                return MediaImmersiveHud(
                                  player: _controller.playerEngine.player,
                                  itemId: currentId,
                                  interactionStream: _controller
                                      .interactionStreamController
                                      .stream,
                                  virtualPositionNotifier: _controller
                                      .playerEngine
                                      .seekController
                                      .virtualPositionNotifier,
                                );
                              },
                            ),
                          ],
                        );
                      },
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
                                _controller.playbackPhase.value.index >=
                                    PlaybackPhase.buildingEngine.index &&
                                !_controller
                                    .playerEngine
                                    .player
                                    .state
                                    .playing &&
                                _controller
                                    .playerEngine
                                    .seekController
                                    .wasPlayingBeforeSeek) {
                              _controller.playerEngine.player.play();
                            }
                          } else {
                            FocusAPI.dispatchBackCommand();
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // 约束保护：强制空气节点用 Positioned.fill 包裹，且常驻以防焦点退回父容器
                    const Positioned.fill(child: SuperFocusAirNode()),

                    // 加载提示文字（覆盖在视频和 HUD 之上，完全接管状态与首帧监听）
                    MediaLoadingMask(controller: _controller),

                    // 左侧悬浮控制菜单
                    if (showMenu)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        child: MediaImmersiveControlPanel(
                          controller: _controller,
                        ),
                      ),

                    // 居中显示的退出确认弹窗
                    if (roomContext.useIsActive('media_home_confirm'))
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: MediaHomeConfirmDialog(
                            onCancel: () {
                              if (_controller
                                  .playerEngine
                                  .seekController
                                  .wasPlayingBeforeSeek) {
                                _controller.playerEngine.player.play();
                              }
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
