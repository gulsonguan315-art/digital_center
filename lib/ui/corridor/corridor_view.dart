import 'package:flutter/material.dart';
import '../../core/base_ui/super_focus_button.dart';
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}
