import 'package:flutter/material.dart';
import '../../core/base_ui/super_focus_button.dart';
import '../../core/focus/focus_widgets.dart';
import 'living_room_room.dart';

class LivingRoomView extends StatelessWidget {
  const LivingRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    return LivingRoomRoom(
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
                    ? Colors.blue.withOpacity(0.05)
                    : Colors.transparent,
                border: Border.all(
                  color: isActive ? Colors.blue : Colors.transparent,
                  width: isActive ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 20,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    '客厅',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.blue : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SuperFocusButton(
                        id: LivingRoomRoom.tableId,
                        label: '餐桌',
                        onPressed: () => print('吃饭'),
                      ),
                      const SizedBox(width: 15),
                      SuperFocusButton(
                        id: LivingRoomRoom.coffeeTableId,
                        label: '茶几',
                        onPressed: () => print('喝茶'),
                      ),
                      const SizedBox(width: 15),
                      SuperFocusButton(
                        id: LivingRoomRoom.sofaId,
                        label: '沙发',
                        onPressed: () => print('坐沙发'),
                      ),
                      const SizedBox(width: 15),
                      // 【错误示范 / Backdoor Error Demo】
                      // 此按钮 ID 为 '空中花园'，虽然 UI 上画出来了，但因为没在 BuildingMap 的'客厅'成员单子里声明
                      // 所以它会触发 FocusManager 的“架构拦截”而无法跳转。
                      SuperFocusButton(
                        id: '空中花园',
                        label: '✿ 秘密花园',
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
    );
  }
}
