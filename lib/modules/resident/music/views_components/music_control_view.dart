import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/models/music_data.dart';
import '../../../../core/data/models/music_config.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../music_model.dart';

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
  final bool isPlaying;
  final double volume;
  final List<double> visualizerHeights;
  final PlaybackMode playMode;
  final dynamic material;

  // callbacks
  final VoidCallback onTogglePlayMode;
  final VoidCallback onFastRewind;
  final VoidCallback onPrev;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onFastForward;
  final ValueChanged<double> onSeek;

  const MusicControlBar({
    super.key,
    required this.currentTrack,
    required this.currentPosition,
    required this.trackDuration,
    required this.isPlaying,
    required this.volume,
    required this.visualizerHeights,
    required this.playMode,
    required this.material,
    required this.onTogglePlayMode,
    required this.onFastRewind,
    required this.onPrev,
    required this.onPlayPause,
    required this.onNext,
    required this.onFastForward,
    required this.onSeek,
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
        ? (currentPosition.inMilliseconds / trackDuration.inMilliseconds).clamp(0.0, 1.0)
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
              Text(_fmt(currentPosition),
                  style: TextStyle(
                      color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
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
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    ),
                    child: ExcludeFocus(
                      child: Slider(
                        value: progress,
                        onChanged: onSeek,
                      ),
                    ),
                  ),
                ),
              ),
              Text(_fmt(trackDuration),
                  style: TextStyle(
                      color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
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
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentTrack != null && currentTrack!.album.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        currentTrack!.album,
                        style: TextStyle(color: colors.textSecondary, fontSize: 11),
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
                    FocusIdentity(
                      id: MusicModel.btnPlayModeId,
                      onPressed: onTogglePlayMode,
                      focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(24))),
                      builder: (ctx, hasFocus) => ExcludeFocus(
                        child: IconButton(
                          icon: Icon(
                            playMode == PlaybackMode.singleLoop
                                ? Icons.repeat_one_rounded
                                : playMode == PlaybackMode.shuffle
                                    ? Icons.shuffle_rounded
                                    : Icons.repeat_rounded,
                          ),
                          color: hasFocus ? colors.accent : colors.textPrimary,
                          iconSize: 24,
                          onPressed: onTogglePlayMode,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FocusIdentity(
                      id: MusicModel.btnFastRewindId,
                      onPressed: onFastRewind,
                      focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(24))),
                      builder: (ctx, hasFocus) => ExcludeFocus(
                        child: IconButton(
                          icon: const Icon(Icons.fast_rewind_rounded),
                          color: hasFocus ? colors.accent : colors.textPrimary,
                          iconSize: 24,
                          onPressed: onFastRewind,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FocusIdentity(
                      id: MusicModel.btnPrevId,
                      onPressed: onPrev,
                      focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(24))),
                      builder: (ctx, hasFocus) => ExcludeFocus(
                        child: IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          color: hasFocus ? colors.accent : colors.textPrimary,
                          iconSize: 26,
                          onPressed: onPrev,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FocusIdentity(
                      id: MusicModel.btnPlayId,
                      onPressed: onPlayPause,
                      focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(22))),
                      builder: (ctx, hasFocus) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surface,
                          border: Border.all(color: colors.accent, width: 2),
                        ),
                        child: ExcludeFocus(
                          child: IconButton(
                            icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            color: colors.accent,
                            onPressed: onPlayPause,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FocusIdentity(
                      id: MusicModel.btnNextId,
                      onPressed: onNext,
                      focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(24))),
                      builder: (ctx, hasFocus) => ExcludeFocus(
                        child: IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          color: hasFocus ? colors.accent : colors.textPrimary,
                          iconSize: 26,
                          onPressed: onNext,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FocusIdentity(
                      id: MusicModel.btnFastForwardId,
                      onPressed: onFastForward,
                      focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(24))),
                      builder: (ctx, hasFocus) => ExcludeFocus(
                        child: IconButton(
                          icon: const Icon(Icons.fast_forward_rounded),
                          color: hasFocus ? colors.accent : colors.textPrimary,
                          iconSize: 24,
                          onPressed: onFastForward,
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
                    // 波形条
                    Row(
                      children: List.generate(visualizerHeights.length, (idx) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 2.5,
                          height: visualizerHeights[idx],
                          margin: const EdgeInsets.only(right: 2.5),
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 16),
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
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.0),
                        ),
                        child: IgnorePointer(
                          child: ExcludeFocus(
                            child: Slider(
                              value: volume,
                              onChanged: (v) {},
                            ),
                          ),
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
