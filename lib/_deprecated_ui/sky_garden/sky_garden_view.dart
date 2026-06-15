import 'package:flutter/material.dart';

import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import '../../core/engine/theme/theme_api.dart';
import '../../ui/base/input/ui_base_button.dart';
import 'sky_garden_room.dart';

class SkyGardenView extends StatelessWidget {
  const SkyGardenView({super.key});

  @override
  Widget build(BuildContext context) {
    return SkyGardenRoom(
      child: ThemeIdentity(
        role: ThemeRole.card,
        child: Builder(
          builder: (context) {
            final isActive = RoomScope.of(context)?.isActive ?? false;
            final material = context.useTheme();

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
                        ? material.colors.accent.withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: material.shape.radius,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.pink.withValues(alpha: 0.2),
                            blurRadius: 20,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Text(
                      'Sky Garden',
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
                          label: 'Swing',
                          onPressed: () {},
                        ),
                        const SizedBox(width: 15),
                        SuperFocusButton(
                          id: SkyGardenRoom.flowersId,
                          label: 'Flowers',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
