import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:superfocus/core/data/models/music_config.dart';
import '../../../../core/data/models/music_data.dart';
import '../../../../core/control/superfocus/focus_api.dart';

typedef FocusSlotBuilder =
    Widget Function(
      Widget Function(
        BuildContext context,
        bool hasFocus,
        VoidCallback? onPressed,
      )
      builder, {
      FocusGeometry? focusGeometry,
    });

/// 🎚️ Zone：music_control
/// 底部播放控制栏 (纯排版 View，无状态)
class MusicControlView extends StatelessWidget {
  final Map<String, Widget> slots;

  const MusicControlView({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return slots['control_bar'] ?? const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// 播放控制条 Widget（进度条 + 控制按钮 + 音量）
// ---------------------------------------------------------------------------

class MusicControlBar extends StatelessWidget {
  final MusicTrack? currentTrack;
  final Duration currentPosition;
  final Duration trackDuration;
  final double volume;
  final dynamic material;
  final ValueChanged<double> onSeek;

  // slots
  final bool isPlaying;
  final PlaybackMode playMode;
  final FocusSlotBuilder playModeSlot;
  final FocusSlotBuilder fastRewindSlot;
  final FocusSlotBuilder prevSlot;
  final FocusSlotBuilder playPauseSlot;
  final FocusSlotBuilder nextSlot;
  final FocusSlotBuilder fastForwardSlot;
  final FocusSlotBuilder recacheSlot;
  final FocusSlotBuilder fullscreenSlot;

  const MusicControlBar({
    super.key,
    required this.currentTrack,
    required this.currentPosition,
    required this.trackDuration,
    required this.volume,
    required this.material,
    required this.onSeek,
    required this.isPlaying,
    required this.playMode,
    required this.playModeSlot,
    required this.fastRewindSlot,
    required this.prevSlot,
    required this.playPauseSlot,
    required this.nextSlot,
    required this.fastForwardSlot,
    required this.recacheSlot,
    required this.fullscreenSlot,
  });

  String _fmt(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = material.colors;
    final progress = trackDuration.inMilliseconds > 0
        ? (currentPosition.inMilliseconds / trackDuration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: material.shape.radius,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 进度条 ──────────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                _fmt(currentPosition),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      activeTrackColor: colors.accent,
                      inactiveTrackColor: colors.border,
                      thumbColor: colors.accent,
                      overlayColor: colors.accent.withValues(alpha: 0.1),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6.0,
                      ),
                    ),
                    child: ExcludeFocus(
                      child: Slider(value: progress, onChanged: onSeek),
                    ),
                  ),
                ),
              ),
              Text(
                _fmt(trackDuration),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── 控制行 ─────────────────────────────────────────────────────────
          Row(
            children: [
              // A. 曲目信息
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentTrack != null
                          ? '${currentTrack!.title} - ${currentTrack!.artist}'
                          : '暂无播放歌曲',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentTrack != null &&
                        currentTrack!.album.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        currentTrack!.album,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // B. 播放按钮组
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    recacheSlot(
                      focusGeometry: const RoundedRectFocusGeometry(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      (ctx, hasFocus, onPressed) => ExcludeFocus(
                        child: MusicControlButton(
                          icon: Icons.replay_rounded,
                          hasFocus: hasFocus,
                          onPressed: onPressed ?? () {},
                          colors: colors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    playModeSlot(
                      focusGeometry: const RoundedRectFocusGeometry(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      (ctx, hasFocus, onPressed) => ExcludeFocus(
                        child: MusicControlButton(
                          icon: playMode == PlaybackMode.singleLoop
                              ? Icons.repeat_one_rounded
                              : playMode == PlaybackMode.shuffle
                              ? Icons.shuffle_rounded
                              : Icons.repeat_rounded,
                          hasFocus: hasFocus,
                          onPressed: onPressed ?? () {},
                          colors: colors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    fastRewindSlot(
                      focusGeometry: const RoundedRectFocusGeometry(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      (ctx, hasFocus, onPressed) => ExcludeFocus(
                        child: MusicControlButton(
                          icon: Icons.fast_rewind_rounded,
                          hasFocus: hasFocus,
                          onPressed: onPressed ?? () {},
                          colors: colors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    prevSlot(
                      focusGeometry: const RoundedRectFocusGeometry(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      (ctx, hasFocus, onPressed) => ExcludeFocus(
                        child: MusicControlButton(
                          icon: Icons.skip_previous_rounded,
                          iconSize: 26,
                          hasFocus: hasFocus,
                          onPressed: onPressed ?? () {},
                          colors: colors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    playPauseSlot(
                      focusGeometry: const RoundedRectFocusGeometry(
                        borderRadius: BorderRadius.all(Radius.circular(22)),
                      ),
                      (ctx, hasFocus, onPressed) => ExcludeFocus(
                        child: MusicPlayButton(
                          isPlaying: isPlaying,
                          hasFocus: hasFocus,
                          onPressed: onPressed ?? () {},
                          colors: colors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    nextSlot(
                      focusGeometry: const RoundedRectFocusGeometry(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      (ctx, hasFocus, onPressed) => ExcludeFocus(
                        child: MusicControlButton(
                          icon: Icons.skip_next_rounded,
                          iconSize: 26,
                          hasFocus: hasFocus,
                          onPressed: onPressed ?? () {},
                          colors: colors,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    fastForwardSlot(
                      focusGeometry: const RoundedRectFocusGeometry(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      (ctx, hasFocus, onPressed) => ExcludeFocus(
                        child: MusicControlButton(
                          icon: Icons.fast_forward_rounded,
                          hasFocus: hasFocus,
                          onPressed: onPressed ?? () {},
                          colors: colors,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // C. 可视化条 + 音量
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      volume == 0
                          ? Icons.volume_off_rounded
                          : (volume < 0.4
                                ? Icons.volume_down_rounded
                                : Icons.volume_up_rounded),
                      color: colors.textSecondary,
                      size: 16,
                    ),
                    SizedBox(
                      width: 120, // 增加滑块宽度
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.0,
                          activeTrackColor: colors.accent,
                          inactiveTrackColor: colors.border,
                          thumbColor: colors.accent,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 4.0,
                          ),
                        ),
                        child: IgnorePointer(
                          child: ExcludeFocus(
                            child: Slider(value: volume, onChanged: (v) {}),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    fullscreenSlot(
                      focusGeometry: const RoundedRectFocusGeometry(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      (ctx, hasFocus, onPressed) => ExcludeFocus(
                        child: MusicControlButton(
                          icon: Icons.fullscreen_rounded,
                          hasFocus: hasFocus,
                          onPressed: onPressed ?? () {},
                          colors: colors,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MusicControlButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final bool hasFocus;
  final VoidCallback onPressed;
  final dynamic colors;

  const MusicControlButton({
    super.key,
    required this.icon,
    this.iconSize = 24,
    required this.hasFocus,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: hasFocus ? colors.accent : colors.textPrimary,
      iconSize: iconSize,
      onPressed: onPressed,
    );
  }
}

class MusicPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool hasFocus;
  final VoidCallback onPressed;
  final dynamic colors;

  const MusicPlayButton({
    super.key,
    required this.isPlaying,
    required this.hasFocus,
    required this.onPressed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: colors.accent, width: 2),
      ),
      child: IconButton(
        icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
        color: colors.accent,
        onPressed: onPressed,
      ),
    );
  }
}
