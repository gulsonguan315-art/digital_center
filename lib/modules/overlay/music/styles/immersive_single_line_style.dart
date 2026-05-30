import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../resident/music/views_components/lrc_parser.dart';

class ImmersiveSingleLineStyle extends StatefulWidget {
  final List<LrcLine> lyrics;
  final int activeIndex;
  final Duration currentPosition;
  final bool isPlaying;

  const ImmersiveSingleLineStyle({
    super.key,
    required this.lyrics,
    required this.activeIndex,
    required this.currentPosition,
    required this.isPlaying,
  });

  @override
  State<ImmersiveSingleLineStyle> createState() => _ImmersiveSingleLineStyleState();
}

class AnimatedLineItem {
  final LrcLine line;
  final int sequenceIndex;
  AnimatedLineItem(this.line, this.sequenceIndex);
}

class _ImmersiveSingleLineStyleState extends State<ImmersiveSingleLineStyle> {
  final List<AnimatedLineItem> _history = [];
  int _lastHandledIndex = -1;

  @override
  void initState() {
    super.initState();
    _syncActiveIndex();
  }

  @override
  void didUpdateWidget(ImmersiveSingleLineStyle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != _lastHandledIndex) {
      _syncActiveIndex();
    }
  }

  void _syncActiveIndex() {
    if (widget.activeIndex < 0 || widget.activeIndex >= widget.lyrics.length) return;
    setState(() {
      _history.add(AnimatedLineItem(widget.lyrics[widget.activeIndex], widget.activeIndex));
      _history.removeWhere((item) => widget.activeIndex - item.sequenceIndex > 4);
      _lastHandledIndex = widget.activeIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_history.isEmpty) {
      return const SizedBox();
    }

    return Center(
      child: SizedBox(
        height: 300, // 提供足够的空间让歌词向上堆叠淡出
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: _history.map((item) {
            final int age = widget.activeIndex - item.sequenceIndex;
            
            return TweenAnimationBuilder<double>(
              key: ValueKey(item.sequenceIndex),
              tween: Tween<double>(begin: age.toDouble(), end: age.toDouble()),
              duration: const Duration(milliseconds: 700), // 固定上推淡出节奏
              curve: Curves.easeOutQuart,
              builder: (context, currentAge, child) {
                // currentAge = 0 时为当前激活行（最底部，原尺寸）
                // currentAge 越大，往上移动越多，同时淡出
                final opacity = (1.0 - (currentAge / 1.5)).clamp(0.0, 1.0);
                final dy = -(currentAge * 80.0); // 每老一岁，向上推 80 像素
                final scale = (1.0 - (currentAge * 0.05)).clamp(0.8, 1.0); // 微微缩小的空间纵深感
                
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomCenter,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  ),
                );
              },
              child: age == 0
                  ? TypewriterLineWidget(
                      line: item.line,
                      currentPosition: widget.currentPosition,
                      isPlaying: widget.isPlaying,
                    )
                  : _buildStaticText(item.line),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStaticText(LrcLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 96),
      child: Text(
        line.text.replaceAll('|', ' '),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.w900,
          height: 1.4,
          letterSpacing: 2.0,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
      ),
    );
  }
}

class TypewriterLineWidget extends StatefulWidget {
  final LrcLine line;
  final Duration currentPosition;
  final bool isPlaying;

  const TypewriterLineWidget({
    super.key,
    required this.line,
    required this.currentPosition,
    required this.isPlaying,
  });

  @override
  State<TypewriterLineWidget> createState() => _TypewriterLineWidgetState();
}

class _TypewriterLineWidgetState extends State<TypewriterLineWidget> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late Duration _basePosition;
  late DateTime _lastUpdateTime;
  late Duration _interpolatedPosition;

  @override
  void initState() {
    super.initState();
    _basePosition = widget.currentPosition;
    _interpolatedPosition = _basePosition;
    _lastUpdateTime = DateTime.now();
    _ticker = createTicker((elapsed) {
      if (widget.isPlaying) {
        setState(() {
          final now = DateTime.now();
          final diff = now.difference(_lastUpdateTime);
          if (diff.inMilliseconds < 1500) {
            _interpolatedPosition = _basePosition + diff;
          } else {
            _interpolatedPosition = _basePosition;
          }
        });
      }
    });
    _ticker.start();
  }

  @override
  void didUpdateWidget(TypewriterLineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition != widget.currentPosition || oldWidget.isPlaying != widget.isPlaying) {
      _basePosition = widget.currentPosition;
      _interpolatedPosition = _basePosition;
      _lastUpdateTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  int _getLastRevealedIndex() {
    if (widget.line.words == null || widget.line.words!.isEmpty) return -2; // 无数据降级标记
    
    int lastIdx = -1;
    for (int i = 0; i < widget.line.words!.length; i++) {
      final wordStart = widget.line.time + widget.line.words![i].relativeStartTime;
      if (_interpolatedPosition >= wordStart) {
        lastIdx = i;
      }
    }
    return lastIdx;
  }

  InlineSpan _buildCursorSpan() {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: SizedBox(
        width: 0,
        height: 64,
        child: OverflowBox(
          maxWidth: 60,
          minWidth: 0,
          alignment: Alignment.centerLeft,
          child: Container(
            width: 32, // 较粗的方块游标
            height: 56,
            margin: const EdgeInsets.only(left: 4, bottom: 4),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastIdx = _getLastRevealedIndex();
    
    // 降级模式：无逐字数据，直接渲染整句并加光标
    if (lastIdx == -2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 96),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: widget.line.text.replaceAll('|', ' '),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8)),
                  ],
                ),
              ),
              _buildCursorSpan(),
            ]
          )
        ),
      );
    }

    // 逐字打字机模式
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 96),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            height: 1.4,
            letterSpacing: 2.0,
          ),
          children: [
            if (lastIdx == -1) _buildCursorSpan(),
            for (int i = 0; i < widget.line.words!.length; i++) ...[
              TextSpan(
                text: widget.line.words![i].text,
                style: TextStyle(
                  color: i <= lastIdx ? Colors.white : Colors.transparent,
                  shadows: i <= lastIdx 
                    ? const [Shadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8))] 
                    : null,
                ),
              ),
              if (i == lastIdx) _buildCursorSpan(),
            ]
          ]
        )
      ),
    );
  }
}
