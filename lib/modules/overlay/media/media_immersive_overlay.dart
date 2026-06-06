import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/control/superfocus/focus_api.dart';
import '../../../core/control/superfocus/interaction_manager.dart';
import '../../../core/control/device_manager/device_manager.dart';
import '../../../core/layout/grid/grid.dart';
import '../../resident/media/media_service.dart';
import '../../../../core/engine/audio/app_audio_service.dart';
import '../../../../core/engine/theme/theme_api.dart';

import '../../../ui/base/surface/dashboard_card.dart';
import '../../../ui/base/text/surface_text.dart';
import 'views_components/media_immersive_control_panel.dart';
import 'views_components/media_immersive_hud.dart';

class MediaImmersiveOverlay extends StatefulWidget {
  final String itemId;

  const MediaImmersiveOverlay({super.key, required this.itemId});

  @override
  State<MediaImmersiveOverlay> createState() => _MediaImmersiveOverlayState();
}

class _MediaImmersiveOverlayState extends State<MediaImmersiveOverlay> {
  late final Player _player;
  late final VideoController _controller;
  
  // 用于通知 HUD 唤起进度条等信息，携带快进提示文字
  final StreamController<String> _interactionStreamController = StreamController<String>.broadcast();
  final ValueNotifier<Duration?> _virtualPositionNotifier = ValueNotifier<Duration?>(null);

  int _lastSeekTime = 0;
  InputSignal? _lastSeekDir;
  
  Duration? _pendingSeekPosition;
  Timer? _seekDebounceTimer;
  bool _wasPlayingBeforeSeek = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _player.setVolume(AppAudioService.instance.volume * 100.0);
    _controller = VideoController(_player);
    final url = MediaService.instance.streamUrl(widget.itemId);
    _player.open(Media(url));

    AppAudioService.instance.addListener(_onGlobalVolumeChanged);
  }

  void _onGlobalVolumeChanged() {
    final vol = AppAudioService.instance.volume * 100.0;
    _player.setVolume(vol);
    _interactionStreamController.add('音量: ${vol.toInt()}%');
  }

  @override
  void dispose() {
    AppAudioService.instance.removeListener(_onGlobalVolumeChanged);
    _seekDebounceTimer?.cancel();
    _interactionStreamController.close();
    _virtualPositionNotifier.dispose();
    _player.dispose();
    super.dispose();
  }

  void _seekRelative(InputSignal dir) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final int deltaMs = now - _lastSeekTime;
    
    // 如果短时间内（<400ms）连续触发同一方向，认为是双击/长按，升级为 30 秒，否则 10 秒
    bool isRapid = (dir == _lastSeekDir) && (deltaMs < 400);
    
    // 防长按高频截流
    if (isRapid && deltaMs < 200 && deltaMs > 0) {
      return; 
    }

    _lastSeekTime = now;
    _lastSeekDir = dir;

    if (_pendingSeekPosition == null) {
      _wasPlayingBeforeSeek = _player.state.playing;
      if (_wasPlayingBeforeSeek) {
        _player.pause();
      }
    }

    final seconds = isRapid ? 30 : 10;
    final delta = Duration(seconds: dir == InputSignal.left ? -seconds : seconds);
    
    Duration currentPos = _pendingSeekPosition ?? _player.state.position;
    Duration newPosition = currentPos + delta;
    if (newPosition.isNegative) newPosition = Duration.zero;
    if (newPosition > _player.state.duration) newPosition = _player.state.duration;

    _pendingSeekPosition = newPosition;
    _virtualPositionNotifier.value = newPosition;
    
    _interactionStreamController.add('${dir == InputSignal.left ? '-' : '+'}${seconds}s');

    _seekDebounceTimer?.cancel();
    _seekDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _player.seek(newPosition);
        if (_wasPlayingBeforeSeek) {
          _player.play();
        }
        _pendingSeekPosition = null;
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _pendingSeekPosition == null) {
            _virtualPositionNotifier.value = null;
          }
        });
      }
    });
  }

  bool _handleLocalInput(InputSignal signal) {
    final showMenu = SuperFocusManager.instance.state.checkIsActive('media_menu');
    final showHomeConfirm = SuperFocusManager.instance.state.checkIsActive('media_home_confirm');

    if (showMenu || showHomeConfirm) {
      if (signal == InputSignal.menu || signal == InputSignal.back) {
        FocusAPI.dispatchBackCommand();
        if (showHomeConfirm && !_player.state.playing && _wasPlayingBeforeSeek) {
           _player.play(); // 如果弹窗取消，恢复播放
        }
        return true;
      }
      return false; // 允许菜单项/弹窗内正常使用方向键与确认键
    } else {
      switch (signal) {
        case InputSignal.menu:
          // 动作触发焦点从空气节点路由转移至菜单 media_menu
          FocusAPI.dispatchAction('media_overlay', 'media_overlay_air_node');
          return true;
        case InputSignal.confirm:
          // Enter/确认键 暂停或播放
          _player.playOrPause();
          return true;
        case InputSignal.left:
          // 左键快退 10 秒 / 长按 30 秒
          _seekRelative(InputSignal.left);
          return true;
        case InputSignal.right:
          // 右键快进 10 秒 / 长按 30 秒
          _seekRelative(InputSignal.right);
          return true;
        case InputSignal.home:
          // 暂停播放，并触发拓扑跳转，显示自定义的焦点弹窗
          _wasPlayingBeforeSeek = _player.state.playing;
          if (_wasPlayingBeforeSeek) _player.pause();
          FocusAPI.dispatchAction('media_overlay', 'media_home_trigger');
          return true;
        case InputSignal.volumeUp:
        case InputSignal.volumeDown:
        case InputSignal.back:
          return false; // 放行给全局处理（回退或调整全局音量）
        default:
          return true; // 空气节点吞噬其他一切操作，防止焦点逃逸
      }
    }
  }

  Widget _buildHomeConfirmDialog(BuildContext context) {
    return Center(
      child: SuperFocusRoom(
        id: 'media_home_confirm',
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '确认返回主页？',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '这将会结束当前的视频播放',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FocusIdentity(
                    id: 'media_home_cancel',
                    onPressed: () {
                      FocusAPI.dispatchBackCommand();
                      if (_wasPlayingBeforeSeek) _player.play();
                    },
                    builder: (ctx, hasFocus) => _buildConfirmButton(
                      title: '取消',
                      hasFocus: hasFocus,
                      isPrimary: false,
                    ),
                  ),
                  FocusIdentity(
                    id: 'media_home_ok',
                    onPressed: () {
                      FocusAPI.dispatchHomeCommand();
                    },
                    builder: (ctx, hasFocus) => _buildConfirmButton(
                      title: '确认返回',
                      hasFocus: hasFocus,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton({
    required String title,
    required bool hasFocus,
    required bool isPrimary,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: hasFocus 
            ? (isPrimary ? Colors.redAccent : Colors.white24) 
            : (isPrimary ? Colors.redAccent.withValues(alpha: 0.8) : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFocus ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: hasFocus || isPrimary ? Colors.white : Colors.white70,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.appBackground,
      child: Scaffold(
        backgroundColor: Colors.black, // 设置为纯黑背景
        body: SuperFocusRoom(
        id: 'media_overlay',
        child: InputInterceptor(
          onSignal: _handleLocalInput,
          child: Builder(
            builder: (roomContext) {
              final showMenu = roomContext.useIsActive('media_menu');
              final scope = roomContext.dependOnInheritedWidgetOfExactType<RoomScope>();
              
              if (scope != null && !scope.isActive) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                });
              }

              return Stack(
                children: [
                  // 真正的播放器组件
                  Positioned.fill(
                    child: Video(
                      controller: _controller,
                      controls: NoVideoControls, // 禁用默认控制面板
                    ),
                  ),

                  // 点击空白处关闭菜单或退出
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (showMenu || roomContext.useIsActive('media_home_confirm')) {
                          FocusAPI.dispatchBackCommand();
                        } else {
                          if (Navigator.canPop(context)) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  // 抽离出的 HUD (暂停提醒、进度条、顶部时间)
                  MediaImmersiveHud(
                    player: _player,
                    interactionStream: _interactionStreamController.stream,
                    virtualPositionNotifier: _virtualPositionNotifier,
                  ),

                  // 约束保护：强制空气节点用 Positioned.fill 包裹，且常驻以防焦点退回父容器
                  const Positioned.fill(
                    child: SuperFocusAirNode(),
                  ),

                  // 左侧悬浮控制菜单
                  if (showMenu)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.only(left: GridContext.fromViewport(MediaQuery.sizeOf(context)).pageInset),
                        alignment: Alignment.centerLeft,
                        child: const MediaImmersiveControlPanel(),
                      ),
                    ),
                    
                  // 居中显示的退出确认弹窗
                  if (roomContext.useIsActive('media_home_confirm'))
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.6),
                        child: _buildHomeConfirmDialog(context),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ));
  }
}
