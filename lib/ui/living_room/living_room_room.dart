import 'package:flutter/material.dart';
import '../../core/focus/focus_widgets.dart';
import '../../core/focus/building_map.dart';

class LivingRoomRoom extends StatelessWidget {
  final Widget child;
  const LivingRoomRoom({super.key, required this.child});

  static const String roomId = '客厅';
  static List<String> get memberIds => BuildingMap.getMembers(roomId);
  static const String tableId = '餐桌';
  static const String coffeeTableId = '茶几';
  static const String sofaId = '沙发';

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}
