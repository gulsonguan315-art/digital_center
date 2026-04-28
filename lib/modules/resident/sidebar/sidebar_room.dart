import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_widgets.dart';

class SidebarRoom extends StatelessWidget {
  const SidebarRoom({super.key, required this.child});

  final Widget child;

  static const String roomId = 'sidebar';
  static const String dashboardId = 'dashboard';
  static const String mediaId = 'media';
  static const String musicId = 'music';
  static const String settingId = 'setting';
  static const String exitId = 'exit';

  // Media 区域子项
  static const String movId = 'mov';
  static const String tvId = 'tv';
  static const String aniId = 'ani';
  static const String docId = 'doc';
  static const String adtId = 'adt';

  // Book 区域子项
  static const String gongId = '宫';
  static const String shangId = '商';
  static const String jiaoId = '角';
  static const String zhiId = '徵';
  static const String yuId = '羽';

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}
