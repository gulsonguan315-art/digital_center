import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../resident/music/music_service.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import '../../../core/control/superfocus/focus_api.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_manager.dart';
import '../../../core/control/device_manager/device_manager.dart';
import '../../../core/data/data_manager.dart';
import 'styles/immersive_scrolling_style.dart';
import 'styles/immersive_single_line_style.dart';
import 'styles/immersive_mood_style.dart';
import 'views_components/shader_visualizer_circle.dart';
import 'views_components/music_immersive_control_panel.dart';

class MusicImmersiveOverlay extends StatefulWidget {
  const MusicImmersiveOverlay({super.key});

  @override
  State<MusicImmersiveOverlay> createState() => _MusicImmersiveOverlayState();
}

class _MusicImmersiveOverlayState extends State<MusicImmersiveOverlay> {
  final FocusNode _focusNode = FocusNode();
  final MusicService _service = MusicService.instance;
  int _currentStyleIndex = 0; // 0: 滚动, 1: 单行, 2: 情绪碎片

  bool _handleLocalInput(InputSignal signal) {
    final showStyleMenu = SuperFocusManager.instance.state.checkIsActive('music_menu');

    if (showStyleMenu) {
      if (signal == InputSignal.menu || signal == InputSignal.back) {
        FocusAPI.dispatchBackCommand();
        return true;
      }
      return false; // 允许菜单项间正常使用方向键与确认键
    } else {
      switch (signal) {
        case InputSignal.left:
          // 快退 10 秒
          final current = _service.playback.currentPosition;
          final target = current - const Duration(seconds: 10);
          _service.playback.seekTo(target < Duration.zero ? Duration.zero : target);
          return true;
        case InputSignal.right:
          // 快进 10 秒
          final current = _service.playback.currentPosition;
          final duration = _service.playback.trackDuration;
          final target = current + const Duration(seconds: 10);
          _service.playback.seekTo(target > duration ? duration : target);
          return true;
        case InputSignal.up:
          _service.playback.playPrevTrack();
          return true;
        case InputSignal.down:
          _service.playback.playNextTrack();
          return true;
        case InputSignal.confirm:
          _service.playback.togglePlayPause();
          return true;
        case InputSignal.menu:
          // 动作触发焦点从空气节点路由转移至菜单 music_menu
          FocusAPI.dispatchAction('music_overlay', 'music_overlay_air_node');
          return true;
        case InputSignal.back:
          return false; // 放行以回退路由
        default:
          return false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _service.addListener(_handleMusicUpdate);
    DataManager.instance.getMusicConfig().then((config) {
      if (mounted) {
        setState(() => _currentStyleIndex = config.immersiveStyleIndex);
      }
    });
  }

  void _setStyle(int index) async {
    setState(() => _currentStyleIndex = index);
    try {
      final config = await DataManager.instance.getMusicConfig();
      DataManager.instance.saveMusicConfig(
        config.copyWith(immersiveStyleIndex: index),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _service.removeListener(_handleMusicUpdate);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleMusicUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = _service.lyrics.parsedLyrics;
    final position = _service.playback.currentPosition;
    final activeIndex = lyrics.isEmpty
        ? -1
        : _service.lyrics.getActiveLyricIndex(position);

    // 单独给 情绪碎片模式 增加 300 毫秒提前量，测试视觉效果
    final moodPosition = position + const Duration(milliseconds: 300);
    final moodActiveIndex = lyrics.isEmpty
        ? -1
        : _service.lyrics.getActiveLyricIndex(moodPosition);

    return Scaffold(
      backgroundColor: Colors.black, // 设置为纯黑背景
      body: SuperFocusRoom(
        id: 'music_overlay',
        child: InputInterceptor(
          onSignal: _handleLocalInput,
          child: Builder(
            builder: (roomContext) {
              final showStyleMenu = roomContext.useIsActive('music_menu');
              final scope = roomContext
                  .dependOnInheritedWidgetOfExactType<RoomScope>();
              if (scope != null && !scope.isActive) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                });
              }

              return Stack(
                children: [
                  // 背景发光与呼吸效果
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (showStyleMenu) {
                          FocusAPI.dispatchBackCommand();
                        } else {
                          if (Navigator.canPop(context)) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 2000),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          // 移除 color: Colors.black 避免与 gradient 冲突
                          gradient: RadialGradient(
                            center: const Alignment(0, 0.2),
                            radius: 1.5,
                            colors: [
                              const Color(0xFF1A1A24).withValues(alpha: 0.8),
                              Colors.black,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 动态切换歌词呈现风格
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _currentStyleIndex == 0
                          ? ImmersiveScrollingStyle(
                              lyrics: lyrics,
                              activeIndex: activeIndex,
                              currentPosition: position,
                            )
                          : _currentStyleIndex == 1
                          ? ImmersiveSingleLineStyle(
                              lyrics: lyrics,
                              activeIndex: activeIndex,
                              currentPosition: position,
                              isPlaying: _service.playback.isPlaying,
                            )
                          : ImmersiveMoodStyle(
                              lyrics: lyrics,
                              activeIndex: moodActiveIndex, // 使用提前了 300ms 的专属下标
                            ),
                    ),
                  ),

                  // 约束保护：强制空气节点用 Positioned.fill 包裹，且常驻以防焦点退回父容器
                  const Positioned.fill(
                    child: SuperFocusAirNode(),
                  ),

                  // 左下角：重低音圆圈 (Bass - 频段0，带径向运动模糊)
                  Positioned(
                    left: 200, // 圆心 X 坐标
                    bottom: 250, // 圆心 Y 坐标
                    width: 0,
                    height: 0,
                    child: ValueListenableBuilder<List<double>>(
                      valueListenable: _service.visualizer.heightsNotifier,
                      builder: (context, heights, _) {
                        final bassEnergy = heights.isNotEmpty
                            ? heights[0]
                            : 0.0;
                        return ShaderVisualizerCircle(
                          energy: bassEnergy,
                          color: Colors.blueAccent,
                          strokeWidth: 2.0,
                        );
                      },
                    ),
                  ),

                  // 右上角：人声圆圈 (Vocals - 频段3，带径向运动模糊)
                  Positioned(
                    right: 200, // 圆心 X 坐标
                    top: 250, // 圆心 Y 坐标
                    width: 0,
                    height: 0,
                    child: ValueListenableBuilder<List<double>>(
                      valueListenable: _service.visualizer.heightsNotifier,
                      builder: (context, heights, _) {
                        final vocalEnergy = heights.isNotEmpty
                            ? heights[3]
                            : 0.0;
                        return ShaderVisualizerCircle(
                          energy: vocalEnergy,
                          color: Colors.pinkAccent,
                          strokeWidth: 1.5,
                        );
                      },
                    ),
                  ),

                  // 底部的扁平化极简菜单
                  if (showStyleMenu)
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: MusicImmersiveControlPanel(
                          currentStyleIndex: _currentStyleIndex,
                          onStyleSelect: _setStyle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
