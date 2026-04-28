import 'package:flutter/material.dart';
import '../../core/focus/focus_widgets.dart';
import '../../core/focus/building_map.dart';

class BedroomRoom extends StatelessWidget {
  final Widget child;
  const BedroomRoom({super.key, required this.child});

  static const String roomId = '卧室';
  static List<String> get memberIds => BuildingMap.getMembers(roomId);
  static const String bedId = '大床';
  static const String wardrobeId = '衣柜';

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}
