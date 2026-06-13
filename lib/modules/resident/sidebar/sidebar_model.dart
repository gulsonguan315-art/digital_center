import 'package:flutter/material.dart';

/// 侧边栏菜单项配置模型
class SidebarItemModel {
  final String id;
  final String label;
  final IconData icon;
  final List<SidebarItemModel>? children;
  final bool isZone;

  const SidebarItemModel({
    required this.id,
    required this.label,
    required this.icon,
    this.children,
    this.isZone = false,
  });
}

/// 侧边栏数据模型：中央 IDs 与 菜单静态配置
class SidebarModel {
  static const String sidebarRoomId = 'sidebar';
  
  static const String dashboardId = 'dashboard';
  static const String mediaId = 'media';
  static const String musicId = 'music';
  static const String bookId = 'book';
  static const String settingId = 'setting';
  static const String exitId = 'exit';

  static const List<SidebarItemModel> menuItems = [
    SidebarItemModel(
      id: dashboardId,
      label: 'DashBoard',
      icon: Icons.dashboard_rounded,
    ),
    SidebarItemModel(
      id: mediaId,
      label: 'media',
      icon: Icons.play_circle_outline_rounded,
      isZone: true,
      children: [
        SidebarItemModel(id: 'mov', label: 'movie', icon: Icons.movie_filter_rounded),
        SidebarItemModel(id: 'tv', label: 'tvShow', icon: Icons.tv_rounded),
        SidebarItemModel(id: 'ani', label: 'Anime', icon: Icons.animation_rounded),
        SidebarItemModel(id: 'doc', label: 'Documentary', icon: Icons.description_rounded),
        SidebarItemModel(id: 'adt', label: 'Adult', icon: Icons.explicit_rounded),
      ],
    ),
    SidebarItemModel(
      id: musicId,
      label: 'music',
      icon: Icons.library_music_rounded,
    ),
    SidebarItemModel(
      id: bookId,
      label: 'book',
      icon: Icons.menu_book_rounded,
      isZone: true,
      children: [
        SidebarItemModel(id: 'sci_fi', label: 'Science Fiction', icon: Icons.rocket_launch_rounded),
        SidebarItemModel(id: 'Humanities', label: 'Humanities', icon: Icons.account_balance_rounded),
        SidebarItemModel(id: 'Power_Fantasy', label: 'Power Fantasy', icon: Icons.local_fire_department_rounded),
      ],
    ),
  ];

  static const SidebarItemModel settingItem = SidebarItemModel(
    id: settingId,
    label: 'setting',
    icon: Icons.settings_rounded,
  );

  static const SidebarItemModel exitItem = SidebarItemModel(
    id: exitId,
    label: 'exit',
    icon: Icons.power_settings_new_rounded,
  );
}
