import 'package:flutter/material.dart';
import '../../../resident/music/views_components/lrc_parser.dart';

class ImmersiveSingleLineStyle extends StatelessWidget {
  final List<LrcLine> lyrics;
  final int activeIndex;

  const ImmersiveSingleLineStyle({
    super.key,
    required this.lyrics,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final line = activeIndex >= 0 && activeIndex < lyrics.length
        ? lyrics[activeIndex].text.replaceAll('|', ' ')
        : (lyrics.isEmpty ? 'No lyrics' : '');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 96),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            line,
            key: ValueKey(line),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              height: 1.4,
              letterSpacing: 2.0,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
