import 'package:flutter/material.dart';
import '../../ui/base/input/ui_base_button.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import 'kitchen_room.dart';

class KitchenView extends StatelessWidget {
  const KitchenView({super.key});

  @override
  Widget build(BuildContext context) {
    return KitchenRoom(
      child: Builder(
        builder: (context) {
          // 在 KitchenRoom (SuperFocusRoom) 内部获取状态
          final bool isActive = RoomScope.of(context)?.isActive ?? false;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isActive ? 1.0 : 0.15,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withOpacity(0.05)
                    : Colors.transparent,
                border: Border.all(
                  color: isActive ? Colors.green : Colors.transparent,
                  width: isActive ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 20,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    '厨房',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SuperFocusButton(
                    id: KitchenRoom.stoveId,
                    label: '灶台',
                    onPressed: () => print('点火'),
                  ),
                  const SizedBox(height: 10),
                  SuperFocusButton(
                    id: KitchenRoom.fridgeId,
                    label: '冰箱',
                    onPressed: () => print('开冰箱'),
                  ),
                  const SizedBox(height: 10),
                  SuperFocusButton(
                    id: '空中花园',
                    label: '✿ 空中花园',
                    onPressed: () {},
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
