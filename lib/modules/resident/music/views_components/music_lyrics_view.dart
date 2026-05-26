import 'package:flutter/material.dart';
import 'lrc_parser.dart';

/// 📜 Zone：music_lyrics (无焦点)
/// 歌词面板 (纯排版 View，无状态)
class MusicLyricsView extends StatelessWidget {
  final List<LrcLine> parsedLyrics;
  final int activeLyricIndex;
  final bool isLoadingLyrics;
  final ScrollController scrollController;
  final dynamic material;

  const MusicLyricsView({
    super.key,
    required this.parsedLyrics,
    required this.activeLyricIndex,
    required this.isLoadingLyrics,
    required this.scrollController,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    final colors = material.colors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: material.shape.radius,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LRC 同步歌词',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoadingLyrics
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                    ),
                  )
                : parsedLyrics.isEmpty
                ? Center(
                    child: Text(
                      '暂无播放歌曲',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.15, 0.85, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(
                            vertical: constraints.maxHeight / 2 - 18.0 > 0
                                ? constraints.maxHeight / 2 - 18.0
                                : 0,
                          ),
                          itemCount: parsedLyrics.length,
                          itemBuilder: (context, index) {
                            final isActive = index == activeLyricIndex;
                            return Container(
                              height: 36,
                              alignment: Alignment.center,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 250),
                                scale: isActive ? 1.12 : 1.0,
                                child: Text(
                                  parsedLyrics[index].text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isActive
                                        ? colors.accent
                                        : colors.textSecondary.withValues(
                                            alpha: 0.8,
                                          ),
                                    fontSize: isActive ? 15 : 13,
                                    fontWeight: isActive
                                        ? FontWeight.w900
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
