import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_api.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_manager.dart';
import 'package:superfocus/core/control/superfocus/topology/building_map.dart';
import '../../../core/stage/stage_manager.dart';
import '../media/media_service.dart';
import '../book/book_service.dart';
import 'sidebar_model.dart';
import 'sidebar_view.dart';
import 'sidebar_tile.dart';

/// 侧边栏装配房间 (总包工头)
class SidebarRoom extends StatefulWidget {
  final Widget? child;
  const SidebarRoom({super.key, this.child});

  @override
  State<SidebarRoom> createState() => _SidebarRoomState();
}

class _SidebarRoomState extends State<SidebarRoom> {
  String? _expandedZoneId;

  @override
  void initState() {
    super.initState();
    MediaService.instance.addListener(_onServiceChanged);
    BookService.instance.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    MediaService.instance.removeListener(_onServiceChanged);
    BookService.instance.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: SidebarModel.sidebarRoomId,
      child: ValueListenableBuilder<FocusTopology>(
        valueListenable: SuperFocusManager.instance.topologyNotifier,
        builder: (context, topology, _) {
          return ListenableBuilder(
            listenable: StageManager.instance.isSecondFloorActive,
            builder: (context, _) {
              return FocusTopologyScope(
                topology: topology,
                child: Builder(
                  builder: (context) {
                    final activeId = _findActiveLeafId(context, SidebarModel.menuItems);
                    
                    final effectiveActiveId = activeId ?? 
                        (_isItemActive(context, SidebarModel.settingId) ? SidebarModel.settingId : 
                        (_isItemActive(context, SidebarModel.exitId) ? SidebarModel.exitId : null));
                    
                    final String autofocusId = effectiveActiveId ?? SidebarModel.dashboardId;
                    final bool isCollapsed = StageManager.instance.isSecondFloorActive.value;

                    return widget.child ?? SidebarView(
                      activeId: effectiveActiveId,
                      expandedZoneId: _expandedZoneId,
                      isCollapsed: isCollapsed,
                      slots: _buildTiles(context, autofocusId, isCollapsed),
                      zoneWrappers: _buildZoneWrappers(),
                      settingSlot: _buildSettingTile(context, autofocusId, isCollapsed),
                      exitSlot: _buildExitTile(context, autofocusId, isCollapsed),
                    );
                  }
                ),
              );
            }
          );
        },
      ),
    );
  }

  /// ✅ 增强型激活判断：支持全域穿透 (扫描所有侧边栏相关房间)
  bool _isItemActive(BuildContext context, String id) {
    if (context.useIsActive(id)) return true;

    // 🌟 修复：影视子分类在其特定激活且 mediaPage 处于当前激活拓扑时方能激活高亮
    if (const ['mov', 'tv', 'ani', 'doc', 'adt'].contains(id)) {
      return id == MediaService.instance.selectedCategory &&
          context.useIsActive('mediaPage');
    }

    // 🌟 图书子分类高亮逻辑
    if (const ['Humanities', 'sci_fi', 'Power_Fantasy'].contains(id)) {
      return id == BookService.instance.selectedLibraryAlias &&
          context.useIsActive('bookPage'); 
    }

    // 1. 确定需要扫描的候选房间列表 (主侧边栏 + 所有 Zone)
    final List<String> candidateRooms = [
      SidebarModel.sidebarRoomId,
      ...SidebarModel.menuItems
          .where((m) => m.children != null && m.children!.isNotEmpty)
          .map((m) => m.id),
    ];

    // 2. 在这些房间中寻找该 ID 的跳转目标
    for (final roomId in candidateRooms) {
      final String? targetRoom = BuildingMap.resolveNavTarget(roomId, id) ??
                               BuildingMap.resolvePortalDestination(roomId, id) ??
                               BuildingMap.resolveRoomEntry(roomId, id);
      
      // 3. 如果找到了目标，且目标处于激活路径，则判定该 ID 激活
      if (targetRoom != null && context.useIsActive(targetRoom)) {
        return true;
      }
    }

    return false;
  }

  String? _findActiveLeafId(BuildContext context, List<SidebarItemModel> items) {
    for (final item in items) {
      if (_isItemActive(context, item.id)) {
        if (item.children != null && item.children!.isNotEmpty) {
          final leafId = _findActiveLeafId(context, item.children!);
          if (leafId != null) return leafId;
          return null; 
        } else {
          return item.id;
        }
      }
    }
    return null;
  }

  Map<String, Widget Function(Widget child)> _buildZoneWrappers() {
    final Map<String, Widget Function(Widget child)> wrappers = {};
    for (final item in SidebarModel.menuItems) {
      if (item.children != null && item.children!.isNotEmpty) {
        wrappers[item.id] = (Widget child) => SuperFocusRoom(
          id: item.id,
          child: child,
        );
      }
    }
    return wrappers;
  }

  Map<String, Widget> _buildTiles(BuildContext context, String autofocusId, bool isCollapsed) {
    final Map<String, Widget> slots = {};
    void collect(List<SidebarItemModel> items, {String? parentRoomId, int depth = 0}) {
      for (final item in items) {
        slots[item.id] = _buildSingleTile(
          context,
          item,
          autofocusId,
          isCollapsed,
          depth,
          parentRoomId: parentRoomId,
        );
        if (item.children != null) {
          collect(item.children!, parentRoomId: item.id, depth: depth + 1);
        }
      }
    }
    collect(SidebarModel.menuItems, parentRoomId: SidebarModel.sidebarRoomId);
    return slots;
  }

  Widget _buildSingleTile(
    BuildContext context,
    SidebarItemModel item,
    String autofocusId,
    bool isCollapsed,
    int depth, {
    String? parentRoomId,
  }) {
    final hasChildren = item.children != null && item.children!.isNotEmpty;

    VoidCallback? tapAction;
    if (hasChildren) {
      tapAction = () {
        setState(() {
          _expandedZoneId = (_expandedZoneId == item.id) ? null : item.id;
        });
      };
    } else if (const ['mov', 'tv', 'ani', 'doc', 'adt'].contains(item.id)) {
      tapAction = () {
        MediaService.instance.setCategory(item.id);
      };
    } else if (const ['Humanities', 'sci_fi', 'Power_Fantasy'].contains(item.id)) {
      tapAction = () {
        BookService.instance.setLibraryByAlias(item.id);
      };
    }

    return SidebarTile(
      id: item.id,
      label: item.label,
      icon: item.icon,
      isActive: _isItemActive(context, item.id),
      autofocus: autofocusId == item.id,
      isExpandable: hasChildren,
      isCollapsed: isCollapsed,
      depth: depth,
      onTap: tapAction,
    );
  }

  Widget _buildSettingTile(BuildContext context, String autofocusId, bool isCollapsed) {
    return SidebarTile(
      id: SidebarModel.settingId,
      label: SidebarModel.settingItem.label,
      icon: SidebarModel.settingItem.icon,
      isActive: _isItemActive(context, SidebarModel.settingId),
      autofocus: autofocusId == SidebarModel.settingId,
      isCollapsed: isCollapsed,
      depth: 0,
      onTap: () => FocusAPI.dispatchAction(
        SidebarModel.sidebarRoomId,
        SidebarModel.settingId,
      ),
    );
  }

  Widget _buildExitTile(BuildContext context, String autofocusId, bool isCollapsed) {
    return SidebarTile(
      id: SidebarModel.exitId,
      label: SidebarModel.exitItem.label,
      icon: SidebarModel.exitItem.icon,
      isActive: _isItemActive(context, SidebarModel.exitId),
      autofocus: autofocusId == SidebarModel.exitId,
      isCollapsed: isCollapsed,
      depth: 0,
      onTap: () => FocusAPI.dispatchAction(
        SidebarModel.sidebarRoomId,
        SidebarModel.exitId,
      ),
    );
  }
}
