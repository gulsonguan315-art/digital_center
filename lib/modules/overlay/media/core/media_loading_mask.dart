import 'dart:async';
import 'package:flutter/material.dart';

import 'media_immersive_controller.dart';

/// 纯 View 层组件：负责沉浸式播放器的加载状态与黑屏遮罩的展示逻辑。
/// 它独立监听 Controller 的业务状态，并负责 'tickCount >= 2' 的首帧解码视觉判断。
class MediaLoadingMask extends StatefulWidget {
  final MediaImmersiveController controller;

  const MediaLoadingMask({super.key, required this.controller});

  @override
  State<MediaLoadingMask> createState() => _MediaLoadingMaskState();
}

class _MediaLoadingMaskState extends State<MediaLoadingMask> {
  String _message = '正在准备...';
  bool _isHidden = false;
  StreamSubscription? _posSub;
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.playbackPhase.addListener(_onPhaseChanged);
    _onPhaseChanged();
  }

  void _onPhaseChanged() {
    if (_isHidden) return;

    final phase = widget.controller.playbackPhase.value;
    switch (phase) {
      case PlaybackPhase.preparing:
        if (mounted) setState(() => _message = '正在准备...');
        break;
      case PlaybackPhase.fetchingHistory:
        if (mounted) setState(() => _message = '正在获取历史记录...');
        break;
      case PlaybackPhase.parsingFirstEpisode:
        if (mounted) setState(() => _message = '正在解析第一集...');
        break;
      case PlaybackPhase.buildingEngine:
        if (mounted) setState(() => _message = '正在构建播放引擎...');
        break;
      case PlaybackPhase.playing:
        if (mounted) setState(() => _message = '正在解码首帧画面...');
        _startListeningToEngine();
        break;
    }
  }

  void _startListeningToEngine() {
    _posSub?.cancel();
    _tickCount = 0;
    _posSub = widget.controller.playerEngine.player.stream.position.listen((pos) {
      if (pos > Duration.zero && !_isHidden) {
        _tickCount++;
        if (_tickCount >= 2) {
          _posSub?.cancel();
          if (mounted) {
            setState(() {
              _isHidden = true;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    widget.controller.playbackPhase.removeListener(_onPhaseChanged);
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black, // 遮挡住尚未准备好的画面
        alignment: Alignment.center,
        child: Text(
          _message,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
