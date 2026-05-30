import 'package:flutter/material.dart';
import 'lrc_parser.dart';

typedef FocusSlotBuilder = Widget Function(Widget Function(BuildContext context, bool hasFocus) builder);

/// 歌词面板
class MusicLyricsView extends StatelessWidget {
  final List<LrcLine> parsedLyrics;
  final int activeLyricIndex;
  final bool isLoadingLyrics;
  final ScrollController scrollController;
  final dynamic material;
  final bool hasFocus;
  final FocusSlotBuilder minusLargeSlot;
  final FocusSlotBuilder minusSmallSlot;
  final FocusSlotBuilder plusSmallSlot;
  final FocusSlotBuilder plusLargeSlot;
  final FocusSlotBuilder exportSlot;
  final int currentOffsetMs;

  const MusicLyricsView({
    super.key,
    required this.parsedLyrics,
    required this.activeLyricIndex,
    required this.isLoadingLyrics,
    required this.scrollController,
    required this.material,
    required this.hasFocus,
    required this.minusLargeSlot,
    required this.minusSmallSlot,
    required this.plusSmallSlot,
    required this.plusLargeSlot,
    required this.exportSlot,
    required this.currentOffsetMs,
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
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'LRC 同步歌词',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: hasFocus ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !hasFocus,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      minusLargeSlot((ctx, hasFocus) => MusicLyricsOffsetButton(
                        icon: Icons.fast_rewind_rounded,
                        label: '-0.5s',
                        hasFocus: hasFocus,
                        colors: colors,
                      )),
                      const SizedBox(width: 8),
                      minusSmallSlot((ctx, hasFocus) => MusicLyricsOffsetButton(
                        icon: Icons.keyboard_double_arrow_left_rounded,
                        label: '-0.1s',
                        hasFocus: hasFocus,
                        colors: colors,
                      )),
                      const SizedBox(width: 8),
                      plusSmallSlot((ctx, hasFocus) => MusicLyricsOffsetButton(
                        icon: Icons.keyboard_double_arrow_right_rounded,
                        label: '+0.1s',
                        hasFocus: hasFocus,
                        colors: colors,
                      )),
                      const SizedBox(width: 8),
                      plusLargeSlot((ctx, hasFocus) => MusicLyricsOffsetButton(
                        icon: Icons.fast_forward_rounded,
                        label: '+0.5s',
                        hasFocus: hasFocus,
                        colors: colors,
                      )),
                    ],
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: hasFocus ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !hasFocus,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (currentOffsetMs != 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Text(
                              '偏移: ${currentOffsetMs > 0 ? '+' : ''}${(currentOffsetMs / 1000).toStringAsFixed(1)}s',
                              style: TextStyle(
                                color: currentOffsetMs > 0
                                    ? colors.accent
                                    : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        exportSlot((ctx, hasFocus) => MusicLyricsOffsetButton(
                          icon: Icons.save_alt_rounded,
                          label: '导出微调并嵌入音频',
                          hasFocus: hasFocus,
                          colors: colors,
                          isPrimary: true,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

class MusicLyricsOffsetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasFocus;
  final dynamic colors;
  final bool isPrimary;

  const MusicLyricsOffsetButton({
    super.key,
    required this.icon,
    required this.label,
    required this.hasFocus,
    required this.colors,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasFocus
            ? colors.accent
            : (isPrimary
                  ? colors.accent.withValues(alpha: 0.1)
                  : Colors.transparent),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasFocus
              ? colors.accent
              : (isPrimary
                    ? colors.accent.withValues(alpha: 0.5)
                    : colors.border),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: hasFocus
                ? colors.surface
                : (isPrimary ? colors.accent : colors.textSecondary),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: hasFocus
                  ? colors.surface
                  : (isPrimary ? colors.accent : colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
