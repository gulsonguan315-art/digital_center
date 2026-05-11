import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/control/superfocus/building_map.dart';
import 'setting_page_view.dart';
import 'setting_page_model.dart';

/// 设置页主房间
class SettingPageRoom extends StatelessWidget {
  final Widget? child;
  const SettingPageRoom({super.key, this.child});

  static const String roomId = SettingPageModel.settingPageId;

  @override
  Widget build(BuildContext context) {
    // 如果没有传入 child，默认展示 SettingPageView
    return SuperFocusRoom(id: roomId, child: child ?? const SettingPageView());
  }
}

/// 主题设置区域房间 (Room/Zone)
class ThemeSettingRoom extends StatelessWidget {
  final Widget child;
  const ThemeSettingRoom({super.key, required this.child});

  static const String roomId = SettingPageModel.themeGroupId;

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}

/// 颜色模式房间 (Room/Zone)
class ThemeColorRoom extends StatelessWidget {
  final Widget child;
  const ThemeColorRoom({super.key, required this.child});

  static const String roomId = SettingPageModel.colorSelectId;
  static List<String> get memberIds => BuildingMap.getMembers(roomId);

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}

/// 视觉风格房间 (Room/Zone)
class ThemeVisualRoom extends StatelessWidget {
  final Widget child;
  const ThemeVisualRoom({super.key, required this.child});

  static const String roomId = SettingPageModel.visualSelectId;
  static List<String> get memberIds => BuildingMap.getMembers(roomId);

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}

class ThemeShapeRoom extends StatelessWidget {
  final Widget child;
  const ThemeShapeRoom({super.key, required this.child});

  static const String roomId = SettingPageModel.shapeSelectId;
  static List<String> get memberIds => BuildingMap.getMembers(roomId);

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(id: roomId, child: child);
  }
}
