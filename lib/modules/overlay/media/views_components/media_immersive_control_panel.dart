import 'package:flutter/material.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/layout/grid/grid.dart';

class MediaImmersiveControlPanel extends StatelessWidget {
  const MediaImmersiveControlPanel({super.key});

  Widget _buildItem({
    required BuildContext context,
    required GridContext grid,
    required String id,
    required String label,
    required IconData icon,
  }) {
    return FocusIdentity(
      id: id,
      onPressed: () {
        // TODO: Handle menu action
      },
      builder: (context, hasFocus) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: grid.units(2.5),
            vertical: grid.units(1.5),
          ),
          decoration: BoxDecoration(
            color: hasFocus ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
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
                color: hasFocus ? Colors.white : Colors.white.withValues(alpha: 0.6),
                size: grid.units(2.5),
              ),
              SizedBox(width: grid.units(1.5)),
              Text(
                label,
                style: TextStyle(
                  color: hasFocus ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  fontSize: grid.units(2.0),
                  fontWeight: hasFocus ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));
    
    return Container(
      width: grid.units(35), // 固定宽度的侧边栏
      padding: EdgeInsets.all(grid.units(2)),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4), // 深色磨砂玻璃感背景
        borderRadius: BorderRadius.circular(grid.units(2.5)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: SuperFocusRoom(
        id: 'media_menu',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildItem(
              context: context,
              grid: grid,
              id: 'media_menu_speed',
              label: '播放速度',
              icon: Icons.speed_rounded,
            ),
            SizedBox(height: grid.units(1)),
            _buildItem(
              context: context,
              grid: grid,
              id: 'media_menu_skip',
              label: '跳过片头片尾',
              icon: Icons.skip_next_rounded,
            ),
            SizedBox(height: grid.units(1)),
            _buildItem(
              context: context,
              grid: grid,
              id: 'media_menu_subtitle',
              label: '选择字幕',
              icon: Icons.subtitles_outlined,
            ),
            SizedBox(height: grid.units(1)),
            _buildItem(
              context: context,
              grid: grid,
              id: 'media_menu_audio',
              label: '选择音轨',
              icon: Icons.audiotrack_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
