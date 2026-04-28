import 'package:flutter/material.dart';
import '../../core/control/superfocus/focus_widgets.dart';
import '../../core/control/superfocus/building_map.dart';

class CorridorRoom extends StatelessWidget {
  final Widget child;
  const CorridorRoom({super.key, required this.child});

  static const String roomId = '走廊';
  static const String toKitchenId = '厨房';
  static const String toLivingRoomId = '客厅';
  static const String toGymId = '健身房';
  static const String toBedroomId = '卧室';
  static List<String> get memberIds => BuildingMap.getMembers(roomId);

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}
