import 'package:flutter/material.dart';
import '../../../../core/data/models/music_data.dart';
import '../../../../core/data/repositories/music_repository.dart';
import '../../../../core/control/superfocus/focus_api.dart';

/// 🎶 Zone：music_list
/// 歌曲播放列表 (纯排版 View，无状态)
class MusicListView extends StatelessWidget {
  final List<MusicTrack> tracks;
  final MusicTrack? currentTrack;
  final bool isPlaying;
  final bool isLoadingTracks;
  final ValueChanged<MusicTrack> onSelectTrack;
  final dynamic material;

  const MusicListView({
    super.key,
    required this.tracks,
    required this.currentTrack,
    required this.isPlaying,
    required this.isLoadingTracks,
    required this.onSelectTrack,
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
                '播放列表 (${tracks.length} 首)',
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
            child: tracks.isEmpty
                ? Center(
                    child: Text(
                      isLoadingTracks ? '正在扫描音轨...' : '此物理文件夹内暂无歌曲',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final isCurrent = currentTrack?.id == track.id;
                      return FocusIdentity(
                        id: 'track_row_${track.id}',
                        focusGeometry: const RoundedRectFocusGeometry(borderRadius: BorderRadius.all(Radius.circular(8))),
                        ensureVisibleCentered: true, // 确保长列表焦点自动居中
                        onPressed: () => onSelectTrack(track),
                        builder: (context, hasFocus) {
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
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

