import 'package:flutter/material.dart';

import '../../core/engine/theme/theme_api.dart';
import '../../ui/base/input/ui_base_button.dart';
import 'corridor_room.dart';

class CorridorView extends StatelessWidget {
  const CorridorView({
    super.key,
    required this.onGoToKitchen,
    required this.onGoToLivingRoom,
    required this.onGoToGym,
  });

  final VoidCallback onGoToKitchen;
  final VoidCallback onGoToLivingRoom;
  final VoidCallback onGoToGym;

  @override
  Widget build(BuildContext context) {
    return CorridorRoom(
      child: ThemeIdentity(
        role: ThemeRole.card,
        child: Builder(
          builder: (context) {
            final material = context.useTheme();

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: material.shape.radius,
                border: Border.all(
                  color: material.colors.accent.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Corridor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SuperFocusButton(
                        id: CorridorRoom.toKitchenId,
                        label: 'Kitchen',
                        autofocus: true,
                        onPressed: onGoToKitchen,
                      ),
                      const SizedBox(width: 20),
                      SuperFocusButton(
                        id: CorridorRoom.toLivingRoomId,
                        label: 'Living Room',
                        onPressed: onGoToLivingRoom,
                      ),
                      const SizedBox(width: 20),
                      SuperFocusButton(
                        id: CorridorRoom.toGymId,
                        label: 'Gym',
                        onPressed: onGoToGym,
                      ),
                      const SizedBox(width: 20),
                      SuperFocusButton(
                        id: CorridorRoom.toBedroomId,
                        label: 'Bedroom',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
