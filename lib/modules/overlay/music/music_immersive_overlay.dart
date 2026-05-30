import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../resident/music/music_service.dart';

class MusicImmersiveOverlay extends StatefulWidget {
  const MusicImmersiveOverlay({super.key});

  @override
  State<MusicImmersiveOverlay> createState() => _MusicImmersiveOverlayState();
}

class _MusicImmersiveOverlayState extends State<MusicImmersiveOverlay> {
  final FocusNode _focusNode = FocusNode();
  final MusicService _service = MusicService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_handleMusicUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _service.removeListener(_handleMusicUpdate);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleMusicUpdate() {
    if (mounted) setState(() {});
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      _service.playback.togglePlayPause();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _service.playback.playPrevTrack();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _service.playback.playNextTrack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = _service.lyrics.parsedLyrics;
    final position = _service.playback.currentPosition;
    final index = lyrics.isEmpty ? -1 : _service.lyrics.getActiveLyricIndex(position);
    final line = index >= 0 && index < lyrics.length ? lyrics[index].text : '';

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 96),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: Text(
                      line.isEmpty ? 'No lyrics' : line,
                      key: ValueKey(line),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 32,
                right: 32,
                child: Opacity(
                  opacity: 0.18,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_return_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ESC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
