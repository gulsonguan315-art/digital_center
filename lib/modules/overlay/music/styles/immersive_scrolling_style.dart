import 'package:flutter/material.dart';
import '../../../resident/music/views_components/lrc_parser.dart';

class ImmersiveScrollingStyle extends StatefulWidget {
  final List<LrcLine> lyrics;
  final int activeIndex;
  final Duration currentPosition;

  const ImmersiveScrollingStyle({
    super.key,
    required this.lyrics,
    required this.activeIndex,
    required this.currentPosition,
  });

  @override
  State<ImmersiveScrollingStyle> createState() => _ImmersiveScrollingStyleState();
}

class _ImmersiveScrollingStyleState extends State<ImmersiveScrollingStyle> {
  late ScrollController _scrollController;
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToActiveLyric(animate: false);
    });
  }

  @override
  void didUpdateWidget(ImmersiveScrollingStyle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != oldWidget.activeIndex) {
      _scrollToActiveLyric();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLyric({bool animate = true}) {
    if (widget.lyrics.isEmpty) return;

    final index = widget.activeIndex;
    if (index == _lastActiveIndex) return;
    _lastActiveIndex = index;

    if (_scrollController.hasClients && index >= 0) {
      final offset = index * 120.0;
      if (animate) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(offset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfHeight = constraints.maxHeight / 2;
          return ListView.builder(
            controller: _scrollController,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: halfHeight - 60,
              bottom: halfHeight,
            ),
            itemCount: widget.lyrics.isEmpty ? 1 : widget.lyrics.length,
            itemBuilder: (context, index) {
              if (widget.lyrics.isEmpty) {
                return Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: const Text(
                    'No lyrics',
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }

              final line = widget.lyrics[index].text.replaceAll('|', ' ');
              if (line.isEmpty) return const SizedBox(height: 120);

              final isActive = index == widget.activeIndex;
              final isPast = index < widget.activeIndex;

              return SizedBox(
                height: 120,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutQuart,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutQuint,
                      scale: isActive ? 1.0 : 0.8,
                      alignment: Alignment.center,
                      child: Text(
                        line,
                        key: ValueKey('${line}_$isActive'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: isPast ? 0.2 : 0.4),
                          fontSize: isActive ? 56 : 42,
                          fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                          height: 1.3,
                          letterSpacing: isActive ? 2.0 : 0.5,
                          shadows: isActive
                              ? [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                  )
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
