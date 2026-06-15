import 'package:flutter/material.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_manager.dart';
import '../../../../core/layout/grid/grid.dart';
import '../core/media_immersive_controller.dart';

class MediaImmersiveControlPanel extends StatelessWidget {
  final MediaImmersiveController controller;

  const MediaImmersiveControlPanel({super.key, required this.controller});

  Widget _buildItem({
    required GridContext grid,
    required String id,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Widget? trailing,
    bool isSelected = false,
    Color? iconColor,
    double? iconSize,
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
            color: hasFocus
                ? Colors.white.withValues(alpha: 0.15)
                : (isSelected
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(grid.units(1.5)),
            border: Border.all(
              color: hasFocus
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                color: iconColor ?? (hasFocus || isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6)),
                size: iconSize ?? grid.units(2.5),
              ),
              SizedBox(width: grid.units(1.5)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: hasFocus || isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: grid.units(2.0),
                    fontWeight: hasFocus || isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
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
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          onPressed: () {}, // BuildingMap自动处理房间跳转
        ),
        SizedBox(height: grid.units(1)),
        _buildItem(
          grid: grid,
          id: 'media_menu_skip',
          label: '跳过片头片尾',
          icon: Icons.skip_next_rounded,
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          onPressed: () {}, // BuildingMap自动处理房间跳转
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
            FocusAPI.dispatchBackCommand();
          },
        ),
        SizedBox(height: grid.units(2)),
        StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: speeds.map((speed) {
              final isSelected = controller.preferencesManager.playbackSpeed == speed;
              return Padding(
                padding: EdgeInsets.only(bottom: grid.units(1)),
                child: _buildItem(
                  grid: grid,
                  id: 'media_menu_speed_$speed',
                  label: '${speed}x',
                  icon: isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  isSelected: isSelected,
                  onPressed: () {
                    controller.preferencesManager.setPlaybackSpeed(speed);
                    setState(() {});
                  },
                ),
              );
            }).toList(),
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
            FocusAPI.dispatchBackCommand();
          },
        ),
        SizedBox(height: grid.units(2)),
        StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildItem(
                grid: grid,
                id: 'media_menu_skip_toggle',
                label: '自动跳过片头片尾',
                icon: controller.preferencesManager.autoSkip
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                isSelected: controller.preferencesManager.autoSkip,
                iconSize: grid.units(3.5),
                iconColor: controller.preferencesManager.autoSkip
                    ? const Color(0xFF00FF66)
                    : Colors.white.withValues(alpha: 0.6),
                onPressed: () {
                  controller.preferencesManager.setAutoSkip(!controller.preferencesManager.autoSkip);
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
                  '${controller.preferencesManager.introDuration ~/ 1000}s',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: grid.units(1.5),
                  ),
                ),
                onPressed: () {
                  controller.preferencesManager.recordIntro();
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
                  '距结束${controller.preferencesManager.outroDuration ~/ 1000}s',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: grid.units(1.5),
                  ),
                ),
                onPressed: () {
                  controller.preferencesManager.recordOutro();
                  setState(() {});
                },
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildMenuLayer(bool isActive, Widget Function() builder) {
    return IgnorePointer(
      ignoring: !isActive,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isActive ? 1.0 : 0.0,
        curve: Curves.easeOutCubic,
        child: builder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));

    return Container(
      width: grid.units(38),
      padding: EdgeInsets.only(
        top: grid.units(8),
        bottom: grid.units(2),
        left: grid.units(2),
        right: grid.units(2),
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(grid.units(2.5)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: SuperFocusRoom(
        id: 'media_menu',
        child: ValueListenableBuilder(
          valueListenable: SuperFocusManager.instance.topologyNotifier,
          builder: (context, topology, _) {
            final isSpeed = SuperFocusManager.instance.state.checkIsActive('media_menu_speed');
            final isSkip = SuperFocusManager.instance.state.checkIsActive('media_menu_skip');
            final isMain = !isSpeed && !isSkip;

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                const Positioned.fill(child: SuperFocusAirNode()),
                _buildMenuLayer(isMain, () => _buildMainMenu(grid)),
                SuperFocusRoom(
                  id: 'media_menu_speed',
                  child: Builder(
                    builder: (ctx) {
                      final isActive = RoomScope.of(ctx)?.isActive ?? false;
                      return _buildMenuLayer(isActive, () => _buildSpeedMenu(grid));
                    }
                  ),
                ),
                SuperFocusRoom(
                  id: 'media_menu_skip',
                  child: Builder(
                    builder: (ctx) {
                      final isActive = RoomScope.of(ctx)?.isActive ?? false;
                      return _buildMenuLayer(isActive, () => _buildSkipMenu(grid));
                    }
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}
