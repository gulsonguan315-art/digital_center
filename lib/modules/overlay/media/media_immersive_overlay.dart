import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/control/superfocus/interaction_manager.dart';
import '../../../../core/engine/theme/theme_api.dart';

import 'core/media_immersive_controller.dart';
import 'views_components/media_home_confirm_dialog.dart';
import 'views_components/media_immersive_control_panel.dart';
import 'views_components/media_immersive_hud.dart';

class MediaImmersiveOverlay extends StatefulWidget {
  final String itemId;
  final int startPositionTicks;

  const MediaImmersiveOverlay({super.key, required this.itemId, this.startPositionTicks = 0});

  @override
  State<MediaImmersiveOverlay> createState() => _MediaImmersiveOverlayState();
}

class _MediaImmersiveOverlayState extends State<MediaImmersiveOverlay> {
  late final MediaImmersiveController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MediaImmersiveController(
      initialItemId: widget.itemId,
      startPositionTicks: widget.startPositionTicks,
      onExitRequest: () {
        if (mounted) FocusAPI.dispatchBackCommand();
      },
    );
  }

  @override
  void dispose() {
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
                final scope = roomContext.dependOnInheritedWidgetOfExactType<RoomScope>();
                final isIntendingToEnter = SuperFocusManager.instance.intentionRoomId.value == 'media_overlay';

                if (scope != null && !scope.isActive && !isIntendingToEnter) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (mounted && Navigator.canPop(context)) {
                      // 立即暂停画面并显示退出提示（网速慢时避免“假死”感）
                      _controller.isExiting.value = true;
                      _controller.exitingMessage.value = '正在保存播放进度...';
                      _controller.engineController.player.pause();

                      await _controller.stopAndReport();

                      _controller.exitingMessage.value = '正在退出播放器...';
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  });
                }

                return Stack(
                  children: [
                    // 真正的播放器组件
                    Positioned.fill(
                      child: Video(
                        controller: _controller.engineController.videoController,
                        controls: NoVideoControls, // 禁用默认控制面板
                      ),
                    ),

                    // 点击空白处关闭菜单或退出
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (showMenu || roomContext.useIsActive('media_home_confirm')) {
                            FocusAPI.dispatchBackCommand();
                            if (roomContext.useIsActive('media_home_confirm') &&
                                !_controller.engineController.player.state.playing &&
                                _controller.seekController.wasPlayingBeforeSeek) {
                              _controller.engineController.player.play();
                            }
                          } else {
                            FocusAPI.dispatchBackCommand();
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // 抽离出的 HUD (暂停提醒、进度条、顶部时间)，外包一层监听 Id 变化
                    ValueListenableBuilder<String>(
                      valueListenable: _controller.currentItemIdNotifier,
                      builder: (context, currentId, child) {
                        return MediaImmersiveHud(
                          player: _controller.engineController.player,
                          itemId: currentId,
                          interactionStream: _controller.interactionStreamController.stream,
                          virtualPositionNotifier: _controller.seekController.virtualPositionNotifier,
                        );
                      },
                    ),

                    // 约束保护：强制空气节点用 Positioned.fill 包裹，且常驻以防焦点退回父容器
                    const Positioned.fill(child: SuperFocusAirNode()),

                    // 左侧悬浮控制菜单
                    if (showMenu)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        child: MediaImmersiveControlPanel(controller: _controller),
                      ),

                    // 居中显示的退出确认弹窗
                    if (roomContext.useIsActive('media_home_confirm'))
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: MediaHomeConfirmDialog(
                            onCancel: () {
                              if (_controller.seekController.wasPlayingBeforeSeek) {
                                _controller.engineController.player.play();
                              }
                            },
                            onConfirm: () {}, // FocusAPI.dispatchHomeCommand() 已经在 Dialog 里调用了
                          ),
                        ),
                      ),

                    // 打开 overlay 时的加载提示（网速慢时显示动态文案）
                    ValueListenableBuilder<bool>(
                      valueListenable: _controller.isPlayerReady,
                      builder: (context, ready, _) {
                        if (ready) return const SizedBox.shrink();
                        return Container(
                          color: Colors.black.withValues(alpha: 0.85),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 20),
                                ValueListenableBuilder<String>(
                                  valueListenable: _controller.loadingMessage,
                                  builder: (ctx, message, __) => Text(
                                    message,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '请稍候...',
                                  style: TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // 退出时的动态提示（暂停画面 + 提示正在保存进度等）
                    ValueListenableBuilder<bool>(
                      valueListenable: _controller.isExiting,
                      builder: (context, exiting, _) {
                        if (!exiting) return const SizedBox.shrink();
                        return Container(
                          color: Colors.black.withValues(alpha: 0.92),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 18),
                                ValueListenableBuilder<String>(
                                  valueListenable: _controller.exitingMessage,
                                  builder: (ctx, message, __) => Text(
                                    message,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '正在处理，请稍候...',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
