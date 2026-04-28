import 'package:flutter/material.dart';
import '../../core/base_ui/super_focus_button.dart';
import '../../core/focus/focus_widgets.dart';
import 'bedroom_room.dart';

class BedroomView extends StatelessWidget {
  const BedroomView({super.key});

  @override
  Widget build(BuildContext context) {
    return BedroomRoom(
      child: Builder(
        builder: (context) {
          final bool isActive = RoomScope.of(context)?.isActive ?? false;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isActive ? 1.0 : 0.15,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.purple.withOpacity(0.05)
                    : Colors.transparent,
                border: Border.all(
                  color: isActive ? Colors.purple : Colors.transparent,
                  width: isActive ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 20,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    '卧室',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.purple : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SuperFocusButton(
                        id: BedroomRoom.bedId,
                        label: '大床',
                        onPressed: () => print('睡觉'),
                      ),
                      const SizedBox(width: 15),
                      SuperFocusButton(
                        id: BedroomRoom.wardrobeId,
                        label: '衣柜',
                        onPressed: () => print('换衣服'),
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
