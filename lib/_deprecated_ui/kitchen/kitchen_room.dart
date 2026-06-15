import 'package:flutter/material.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import 'package:superfocus/core/control/superfocus/topology/building_map.dart';

class KitchenRoom extends StatelessWidget {
  final Widget child;
  const KitchenRoom({super.key, required this.child});

  static const String roomId = '厨房';
  static const String fridgeId = '冰箱';
  static const String stoveId = '灶台';
  static List<String> get memberIds => BuildingMap.getMembers(roomId);

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}
