import 'package:flutter/material.dart';
import '../../../resident/music/views_components/lrc_parser.dart';
import '../../../resident/music/engine/lyrics_chunker.dart';

class ImmersiveMoodStyle extends StatefulWidget {
  final List<LrcLine> lyrics;
  final int activeIndex;

  const ImmersiveMoodStyle({
    super.key,
    required this.lyrics,
    required this.activeIndex,
  });

  @override
  State<ImmersiveMoodStyle> createState() => _ImmersiveMoodStyleState();
}

class _ImmersiveMoodStyleState extends State<ImmersiveMoodStyle> {
  int _cachedIndex = -1;
  List<MoodChunk> _cachedChunks = [];

  @override
  void initState() {
    super.initState();
    _updateCache();
  }

  @override
  void didUpdateWidget(ImmersiveMoodStyle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex || oldWidget.lyrics != widget.lyrics) {
      _updateCache();
    }
  }

  void _updateCache() {
    if (widget.activeIndex < 0 || widget.activeIndex >= widget.lyrics.length) {
      _cachedIndex = widget.activeIndex;
      _cachedChunks = [];
      return;
    }

    if (_cachedIndex != widget.activeIndex) {
      _cachedIndex = widget.activeIndex;
      final lineContent = widget.lyrics[widget.activeIndex].text;
      _cachedChunks = LyricsChunker.chunkLine(lineContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInQuint,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        // 用 _cachedIndex 作为 key，确保每次句子改变都会触发出场、入场动画
        child: _cachedChunks.isEmpty
            ? SizedBox(key: ValueKey('empty_$_cachedIndex'))
            : Wrap(
                key: ValueKey('line_$_cachedIndex'),
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.end, // 底部对齐
                spacing: 8.0, // 字块之间的间距
                runSpacing: 12.0, // 换行时的间距
                children: _cachedChunks.map((chunk) {
                  return Text(
                    chunk.text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: chunk.alpha),
                      fontSize: 48.0 * chunk.scale,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: 2.0,
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}
