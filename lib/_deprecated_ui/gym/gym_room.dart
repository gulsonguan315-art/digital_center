import 'package:flutter/material.dart';
import '../../core/control/superfocus/focus_widgets.dart';
import '../../core/control/superfocus/building_map.dart';

/// 健身房主房间 (Standalone Hub)
class GymRoom extends StatelessWidget {
  final Widget child;
  const GymRoom({super.key, required this.child});

  static const String roomId = '健身房';
  static List<String> get memberIds => BuildingMap.getMembers(roomId);

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}

/// 健身房 -> 有氧区 (Passable Zone - 会自动根据地图上的 + 号识别)
class CardioRoom extends StatelessWidget {
  final Widget child;
  const CardioRoom({super.key, required this.child});

  static const String roomId = '有氧区';
  static List<String> get memberIds => BuildingMap.getMembers(roomId);

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}

/// 健身房 -> 力量区 (Passable Zone - 会自动根据地图上的 + 号识别)
class StrengthRoom extends StatelessWidget {
  final Widget child;
  const StrengthRoom({super.key, required this.child});

  static const String roomId = '力量区';
  static List<String> get memberIds => BuildingMap.getMembers(roomId);

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}
