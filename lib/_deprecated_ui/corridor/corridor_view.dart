import 'package:flutter/material.dart';
import '../../ui/base/input/ui_base_button.dart';
import '../../core/engine/theme/del_theme_colors.dart';
import '../../core/engine/theme/del_theme_visuals.dart';
import 'corridor_room.dart';

class CorridorView extends StatelessWidget {
  final VoidCallback onGoToKitchen;
  final VoidCallback onGoToLivingRoom;
  final VoidCallback onGoToGym;

  const CorridorView({
    super.key,
    required this.onGoToKitchen,
    required this.onGoToLivingRoom,
    required this.onGoToGym,
  });

  @override
  Widget build(BuildContext context) {
    return CorridorRoom(
      child: Builder(
        builder: (context) {
          final themeColors = Theme.of(context).extension<ThemeColors>()!;
          final themeVisuals = Theme.of(context).extension<ThemeVisuals>()!;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: themeVisuals.defaultRadius,
              border: Border.all(
                color: themeColors.adormColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '走廊 (Room: 走廊)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SuperFocusButton(
                      id: CorridorRoom.toKitchenId,
                      label: '去厨房',
                      autofocus: true,
                      onPressed: onGoToKitchen,
                    ),
                    const SizedBox(width: 20),
                    SuperFocusButton(
                      id: CorridorRoom.toLivingRoomId,
                      label: '去客厅',
                      onPressed: onGoToLivingRoom,
                    ),
                    const SizedBox(width: 20),
                    SuperFocusButton(
                      id: CorridorRoom.toGymId,
                      label: '去健身房',
                      onPressed: onGoToGym,
                    ),
                    const SizedBox(width: 20),
                    SuperFocusButton(
                      id: CorridorRoom.toBedroomId,
                      label: '去卧室',
                      onPressed: () {}, // 自动由地图驱动
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
