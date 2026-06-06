import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import '../../../../core/layout/grid/grid.dart';
import '../../../../core/engine/theme/theme_api.dart';

class MediaImmersiveHud extends StatefulWidget {
  final Player player;
  /// 用于通知 HUD 触发临时显示的流（带有要显示的中间提示文字，比如 "+10s"）
  final Stream<String>? interactionStream;
  /// 用于接收长按快进期间尚未提交给底层 player 的虚拟进度，以实现进度条的无缝推进
  final ValueNotifier<Duration?>? virtualPositionNotifier;

  const MediaImmersiveHud({
    super.key,
    required this.player,
    this.interactionStream,
    this.virtualPositionNotifier,
  });

  @override
  State<MediaImmersiveHud> createState() => _MediaImmersiveHudState();
}

class _MediaImmersiveHudState extends State<MediaImmersiveHud> {
  bool _isPlaying = true;
  bool _showPlayIconTemporary = false;
  bool _showSeekHudTemporary = false;
  String _seekText = '';
  
  Duration _realPosition = Duration.zero;
  Duration? _virtualPosition;
  Duration _duration = Duration.zero;

  late StreamSubscription<bool> _playingSub;
  late StreamSubscription<Duration> _positionSub;
  late StreamSubscription<Duration> _durationSub;
  StreamSubscription<String>? _interactionSub;

  Timer? _playIconTimer;
  Timer? _seekHudTimer;
  Timer? _volumeHudTimer;

  bool _showVolumeHudTemporary = false;
  String _volumeText = '';

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.player.state.playing;
    _realPosition = widget.player.state.position;
    _duration = widget.player.state.duration;

    _playingSub = widget.player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() {
        _isPlaying = playing;
        if (playing) {
          _showPlayIconTemporary = true;
          _playIconTimer?.cancel();
          _playIconTimer = Timer(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() => _showPlayIconTemporary = false);
            }
          });
        } else {
          _showPlayIconTemporary = false;
          _playIconTimer?.cancel();
        }
      });
    });

    _positionSub = widget.player.stream.position.listen((pos) {
      if (mounted) {
        setState(() => _realPosition = pos);
      }
    });

    _durationSub = widget.player.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    if (widget.interactionStream != null) {
      _interactionSub = widget.interactionStream!.listen((msg) {
        if (msg.startsWith('音量')) {
          _triggerVolumeHud(msg);
        } else {
          _triggerSeekHud(msg);
        }
      });
    }

    widget.virtualPositionNotifier?.addListener(_onVirtualPositionChanged);
  }

  void _onVirtualPositionChanged() {
    if (!mounted) return;
    setState(() {
      _virtualPosition = widget.virtualPositionNotifier?.value;
    });
  }

  @override
  void didUpdateWidget(MediaImmersiveHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.virtualPositionNotifier != widget.virtualPositionNotifier) {
      oldWidget.virtualPositionNotifier?.removeListener(_onVirtualPositionChanged);
      widget.virtualPositionNotifier?.addListener(_onVirtualPositionChanged);
    }
  }

  void _triggerSeekHud(String msg) {
    if (!mounted) return;
    setState(() {
      _showSeekHudTemporary = true;
      _seekText = msg;
    });
    _seekHudTimer?.cancel();
    _seekHudTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSeekHudTemporary = false;
          _seekText = '';
        });
      }
    });
  }

  void _triggerVolumeHud(String msg) {
    if (!mounted) return;
    setState(() {
      _showVolumeHudTemporary = true;
      _volumeText = msg;
    });
    _volumeHudTimer?.cancel();
    _volumeHudTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showVolumeHudTemporary = false;
          _volumeText = '';
        });
      }
    });
  }

  @override
  void dispose() {
    widget.virtualPositionNotifier?.removeListener(_onVirtualPositionChanged);
    _playingSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _interactionSub?.cancel();
    _playIconTimer?.cancel();
    _seekHudTimer?.cancel();
    _volumeHudTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));
    final material = context.useTheme();
    
    // UI 是否该展示 HUD (暂停，或者正在快进/退)
    final bool showHud = !_isPlaying || _showSeekHudTemporary;
    
    // 中心图标显隐逻辑：暂停时一直显示，播放时仅短暂显示
    final bool showCenterIcon = !_isPlaying || _showPlayIconTemporary || (_showSeekHudTemporary && _seekText.isNotEmpty);
    
    IconData centerIcon;
    if (_showSeekHudTemporary && _seekText.isNotEmpty) {
      centerIcon = _seekText.startsWith('+') ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded;
    } else {
      centerIcon = _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded;
    }

    Duration currentDisplayPosition = _virtualPosition ?? _realPosition;

    // 计算预计结束时间
    DateTime now = DateTime.now();
    DateTime endTime = now.add(_duration - currentDisplayPosition);
    String currentTimeStr = DateFormat('HH:mm').format(now);
    String endTimeStr = DateFormat('HH:mm').format(endTime);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // 顶部时间信息栏
            Positioned(
              top: grid.units(4),
              left: grid.pageInset,
              right: grid.pageInset,
              child: AnimatedOpacity(
                opacity: showHud ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentTimeStr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: grid.units(3.0),
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                    Text(
                      '预计 $endTimeStr 播完',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: grid.units(1.8),
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 中心大图标（播放/暂停/快进退）及文字
            Center(
              child: AnimatedOpacity(
                opacity: showCenterIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 左侧占位/文字区，固定宽度以保证圆圈绝对居中
                    SizedBox(
                      width: grid.units(12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: (_showSeekHudTemporary && _seekText.isNotEmpty && _seekText.startsWith('-'))
                            ? Padding(
                                padding: EdgeInsets.only(right: grid.units(2)),
                                child: Text(
                                  _seekText,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: grid.units(2.5),
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),

                    // 中间圆圈
                    Container(
                      padding: EdgeInsets.all(grid.units(3)),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        centerIcon,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: grid.units(8),
                      ),
                    ),

                    // 右侧占位/文字区，与左侧等宽以保证绝对居中
                    SizedBox(
                      width: grid.units(12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: (_showSeekHudTemporary && _seekText.isNotEmpty && _seekText.startsWith('+'))
                            ? Padding(
                                padding: EdgeInsets.only(left: grid.units(2)),
                                child: Text(
                                  _seekText,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: grid.units(2.5),
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部播放进度条
            Positioned(
              bottom: grid.units(4),
              left: grid.pageInset,
              right: grid.pageInset,
              child: AnimatedOpacity(
                opacity: showHud ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Row(
                  children: [
                    Text(
                      _formatDuration(currentDisplayPosition),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: grid.units(1.6),
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                    SizedBox(width: grid.units(2)),
                    Expanded(
                      child: Container(
                        height: grid.units(0.6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(grid.units(0.3)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final durationMs = _duration.inMilliseconds;
                            if (durationMs <= 0) return const SizedBox.shrink();

                            final realProgress = (_realPosition.inMilliseconds / durationMs).clamp(0.0, 1.0);
                            double? virtualProgress;
                            if (_virtualPosition != null) {
                              virtualProgress = (_virtualPosition!.inMilliseconds / durationMs).clamp(0.0, 1.0);
                            }

                            final trackWidth = constraints.maxWidth;

                            return Stack(
                              children: [
                                // Virtual/Delta Track
                                if (virtualProgress != null)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: trackWidth * (realProgress > virtualProgress ? realProgress : virtualProgress),
                                      decoration: BoxDecoration(
                                        color: material.colors.accent.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(grid.units(0.3)),
                                      ),
                                    ),
                                  ),
                                  
                                // Base/Solid Track
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: trackWidth * (virtualProgress != null ? (realProgress < virtualProgress ? realProgress : virtualProgress) : realProgress),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(grid.units(0.3)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: grid.units(2)),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: grid.units(1.6),
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 独立音量提示 HUD (顶部居中或右侧)
            if (_showVolumeHudTemporary)
              Positioned(
                top: grid.units(6),
                right: grid.pageInset,
                child: AnimatedOpacity(
                  opacity: _showVolumeHudTemporary ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: grid.units(3), vertical: grid.units(1.5)),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(grid.units(4)),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded, color: Colors.white, size: grid.units(3)),
                        SizedBox(width: grid.units(1)),
                        Text(
                          _volumeText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: grid.units(2.2),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
