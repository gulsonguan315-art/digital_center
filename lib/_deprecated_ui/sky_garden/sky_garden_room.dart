import 'package:flutter/material.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import 'package:superfocus/core/control/superfocus/topology/building_map.dart';

class SkyGardenRoom extends StatelessWidget {
  final Widget child;
  const SkyGardenRoom({super.key, required this.child});

  static const String roomId = '空中花园';
  static List<String> get memberIds => BuildingMap.getMembers(roomId);
  static const String swingId = '秋千';
  static const String flowersId = '花盆';

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}
