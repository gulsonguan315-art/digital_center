import 'package:flutter/material.dart';
import '../../ui/base/input/super_focus_button.dart';
import '../../core/control/superfocus/focus_widgets.dart';
import '../../core/engine/theme/theme_colors.dart';
import '../../core/engine/theme/theme_visuals.dart';
import 'sky_garden_room.dart';

class SkyGardenView extends StatelessWidget {
  const SkyGardenView({super.key});

  @override
  Widget build(BuildContext context) {
    return SkyGardenRoom(
      child: Builder(
        builder: (context) {
          final bool isActive = RoomScope.of(context)?.isActive ?? false;
          final themeColors = Theme.of(context).extension<ThemeColors>()!;
          final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isActive ? 1.0 : 0.15,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: isActive
                      ? themeColors.adormColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: themeVisuals.defaultRadius,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.2),
                          blurRadius: 20,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    '✿ 空中花园 ✿',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.pink : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SuperFocusButton(
                        id: SkyGardenRoom.swingId,
                        label: '秋千',
                        onPressed: () => print('摇啊摇'),
                      ),
                      const SizedBox(width: 15),
                      SuperFocusButton(
                        id: SkyGardenRoom.flowersId,
                        label: '花盆',
                        onPressed: () => print('浇花'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
