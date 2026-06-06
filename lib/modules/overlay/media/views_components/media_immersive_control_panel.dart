import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/layout/grid/grid.dart';
import '../core/media_immersive_controller.dart';

class MediaImmersiveControlPanel extends StatefulWidget {
  final MediaImmersiveController controller;
  
  const MediaImmersiveControlPanel({super.key, required this.controller});

  @override
  State<MediaImmersiveControlPanel> createState() => _MediaImmersiveControlPanelState();
}

class _MediaImmersiveControlPanelState extends State<MediaImmersiveControlPanel> {
  String _activeMenu = 'main';

  Widget _buildItem({
    required GridContext grid,
    required String id,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Widget? trailing,
    bool isSelected = false,
  }) {
    return FocusIdentity(
      id: id,
      onPressed: onPressed,
      builder: (context, hasFocus) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: grid.units(2.5),
            vertical: grid.units(1.5),
          ),
          decoration: BoxDecoration(
            color: hasFocus ? Colors.white.withValues(alpha: 0.15) : (isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(grid.units(1.5)),
            border: Border.all(
              color: hasFocus ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                color: hasFocus || isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                size: grid.units(2.5),
              ),
              SizedBox(width: grid.units(1.5)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: hasFocus || isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                    fontSize: grid.units(2.0),
                    fontWeight: hasFocus || isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainMenu(GridContext grid) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildItem(
          grid: grid,
          id: 'media_menu_speed',
          label: '播放速度',
          icon: Icons.speed_rounded,
          trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5)),
          onPressed: () {
            setState(() { _activeMenu = 'speed'; });
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) FocusAPI.dispatchAction('media_menu', 'media_menu_speed_back');
            });
          },
        ),
        SizedBox(height: grid.units(1)),
        _buildItem(
          grid: grid,
          id: 'media_menu_skip',
          label: '跳过片头片尾',
          icon: Icons.skip_next_rounded,
          trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5)),
          onPressed: () {
            setState(() { _activeMenu = 'skip'; });
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) FocusAPI.dispatchAction('media_menu', 'media_menu_skip_back');
            });
          },
        ),
        SizedBox(height: grid.units(1)),
        _buildItem(
          grid: grid,
          id: 'media_menu_subtitle',
          label: '选择字幕 (暂未实现)',
          icon: Icons.subtitles_outlined,
          onPressed: () {},
        ),
        SizedBox(height: grid.units(1)),
        _buildItem(
          grid: grid,
          id: 'media_menu_audio',
          label: '选择音轨 (暂未实现)',
          icon: Icons.audiotrack_rounded,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSpeedMenu(GridContext grid) {
    final speeds = [1.0, 1.25, 1.5, 1.75, 2.0];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildItem(
          grid: grid,
          id: 'media_menu_speed_back',
          label: '返回上一级',
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            setState(() { _activeMenu = 'main'; });
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) FocusAPI.dispatchAction('media_menu', 'media_menu_speed');
            });
          },
        ),
        SizedBox(height: grid.units(2)),
        ...speeds.map((speed) {
          final isSelected = widget.controller.playbackSpeed == speed;
          return Padding(
            padding: EdgeInsets.only(bottom: grid.units(1)),
            child: _buildItem(
              grid: grid,
              id: 'media_menu_speed_$speed',
              label: '${speed}x',
              icon: isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              isSelected: isSelected,
              onPressed: () {
                widget.controller.setPlaybackSpeed(speed);
                setState(() {});
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSkipMenu(GridContext grid) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildItem(
          grid: grid,
          id: 'media_menu_skip_back',
          label: '返回上一级',
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            setState(() { _activeMenu = 'main'; });
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) FocusAPI.dispatchAction('media_menu', 'media_menu_skip');
            });
          },
        ),
        SizedBox(height: grid.units(2)),
        _buildItem(
          grid: grid,
          id: 'media_menu_skip_toggle',
          label: '自动跳过片头片尾',
          icon: widget.controller.autoSkip ? Icons.toggle_on : Icons.toggle_off_outlined,
          isSelected: widget.controller.autoSkip,
          onPressed: () {
            widget.controller.setAutoSkip(!widget.controller.autoSkip);
            setState(() {});
          },
        ),
        SizedBox(height: grid.units(1)),
        _buildItem(
          grid: grid,
          id: 'media_menu_skip_intro',
          label: '记录片头 (当前位置)',
          icon: Icons.login_rounded,
          trailing: Text(
            '${widget.controller.introDuration ~/ 1000}s',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: grid.units(1.5)),
          ),
          onPressed: () {
            widget.controller.recordIntro();
            setState(() {});
          },
        ),
        SizedBox(height: grid.units(1)),
        _buildItem(
          grid: grid,
          id: 'media_menu_skip_outro',
          label: '记录片尾 (当前位置)',
          icon: Icons.logout_rounded,
          trailing: Text(
            '距结束${widget.controller.outroDuration ~/ 1000}s',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: grid.units(1.5)),
          ),
          onPressed: () {
            widget.controller.recordOutro();
            setState(() {});
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));
    
    Widget content;
    switch (_activeMenu) {
      case 'speed':
        content = _buildSpeedMenu(grid);
        break;
      case 'skip':
        content = _buildSkipMenu(grid);
        break;
      default:
        content = _buildMainMenu(grid);
    }

    return Container(
      width: grid.units(38),
      padding: EdgeInsets.all(grid.units(2)),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(grid.units(2.5)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: SuperFocusRoom(
        id: 'media_menu',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(_activeMenu),
            child: content,
          ),
        ),
      ),
    );
  }
}
