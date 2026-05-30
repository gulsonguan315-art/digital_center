import 'package:flutter/material.dart';
import '../../../../core/data/models/music_data.dart';
import '../../../../core/data/repositories/music_repository.dart';
import '../../../../core/control/superfocus/focus_api.dart';

typedef TrackSlotBuilder = Widget Function(
  BuildContext context,
  int index,
  Widget Function(BuildContext context, bool hasFocus, VoidCallback? onPressed, {required MusicTrack track, required bool isCurrent, required bool isPlaying}) builder, {
  FocusGeometry? focusGeometry,
});


/// 🎶 Zone：music_list
/// 歌曲播放列表 (纯排版 View，无状态)
class MusicListView extends StatelessWidget {
  final int trackCount;
  final TrackSlotBuilder trackSlot;
  final bool isLoadingTracks;
  final dynamic material;

  const MusicListView({
    super.key,
    required this.trackCount,
    required this.trackSlot,
    required this.isLoadingTracks,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    final colors = material.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: material.shape.radius,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '播放列表 ($trackCount 首)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              if (isLoadingTracks)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: trackCount == 0
                ? Center(
                    child: Text(
                      isLoadingTracks ? '正在扫描音轨...' : '此物理文件夹内暂无歌曲',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: trackCount,
                    itemBuilder: (ctx, index) => trackSlot(
                      ctx,
                      index,
                      focusGeometry: const RoundedRectFocusGeometry(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      (ctx, hasFocus, onPressed, {required track, required isCurrent, required isPlaying}) {
                        return MusicTrackRow(
                          track: track,
                          index: index,
                          isCurrent: isCurrent,
                          isPlaying: isPlaying,
                          hasFocus: hasFocus,
                          material: material,
                        );
                      }
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class MusicTrackRow extends StatelessWidget {
  final MusicTrack track;
  final int index;
  final bool isCurrent;
  final bool isPlaying;
  final bool hasFocus;
  final dynamic material;

  const MusicTrackRow({
    super.key,
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.isPlaying,
    required this.hasFocus,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    final colors = material.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent ? colors.accent.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: isCurrent && isPlaying
                ? Icon(Icons.volume_up_rounded, color: colors.accent, size: 14)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrent ? colors.accent : colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    track.title,
                    style: TextStyle(
                      color: isCurrent ? colors.accent : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (MusicRepository.instance.isTrackCached(track)) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.offline_pin_rounded,
                    size: 14,
                    color: isCurrent
                        ? colors.accent.withValues(alpha: 0.8)
                        : colors.textSecondary.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              track.artist,
              style: TextStyle(
                color: isCurrent
                    ? colors.accent.withValues(alpha: 0.8)
                    : colors.textPrimary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            track.formattedDuration,
            style: TextStyle(
              color: isCurrent ? colors.accent : colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
