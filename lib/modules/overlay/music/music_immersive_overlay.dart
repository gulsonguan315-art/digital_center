import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../resident/music/music_service.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import 'styles/immersive_scrolling_style.dart';
import 'styles/immersive_single_line_style.dart';
import 'styles/immersive_mood_style.dart';

class MusicImmersiveOverlay extends StatefulWidget {
  const MusicImmersiveOverlay({super.key});

  @override
  State<MusicImmersiveOverlay> createState() => _MusicImmersiveOverlayState();
}

class _MusicImmersiveOverlayState extends State<MusicImmersiveOverlay> {
  final FocusNode _focusNode = FocusNode();
  final MusicService _service = MusicService.instance;
  int _currentStyleIndex = 0; // 0: 滚动, 1: 单行

  @override
  void initState() {
    super.initState();
    _service.addListener(_handleMusicUpdate);
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

  Widget _buildStyleDot(int index, bool hasFocus) {
    final isSelected = _currentStyleIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: hasFocus ? 20 : (isSelected ? 16 : 12),
      height: hasFocus ? 20 : (isSelected ? 16 : 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
        boxShadow: hasFocus || isSelected
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: hasFocus ? 0.8 : 0.4),
                  blurRadius: hasFocus ? 16 : 8,
                  spreadRadius: hasFocus ? 4 : 2,
                ),
              ]
            : null,
      ),
    );
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
        child: Builder(
          builder: (roomContext) {
            // 必须在 Builder 内部调用 RoomScope.of() 才能监听到上述注册的房间状态
            final scope = roomContext
                .dependOnInheritedWidgetOfExactType<RoomScope>();
            if (scope != null && !scope.isActive) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              });
            }

            return Focus(
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;

                if (event.logicalKey == LogicalKeyboardKey.space) {
                  _service.playback.togglePlayPause();
                  return KeyEventResult.handled;
                }
                // 注：移除左右键拦截，以便 SuperFocus 能正常移动焦点
                return KeyEventResult.ignored;
              },
              child: Stack(
                children: [
                  // 背景发光与呼吸效果
                  Positioned.fill(
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

                  // 底部的两个小圆圈指示器
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FocusIdentity(
                          id: 'style_scrolling',
                          autofocus: true, // 进入房间自动聚焦第一个圆圈
                          onPressed: () =>
                              setState(() => _currentStyleIndex = 0),
                          builder: (context, hasFocus) => Padding(
                            padding: const EdgeInsets.all(8.0), // 扩大可点击/发光区域
                            child: _buildStyleDot(0, hasFocus),
                          ),
                        ),
                        const SizedBox(width: 32),
                        FocusIdentity(
                          id: 'style_single_line',
                          onPressed: () =>
                              setState(() => _currentStyleIndex = 1),
                          builder: (context, hasFocus) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildStyleDot(1, hasFocus),
                          ),
                        ),
                        const SizedBox(width: 32),
                        FocusIdentity(
                          id: 'style_mood',
                          onPressed: () =>
                              setState(() => _currentStyleIndex = 2),
                          builder: (context, hasFocus) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _buildStyleDot(2, hasFocus),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
