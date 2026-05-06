import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/control/superfocus/focus_api.dart';

import '../../../core/layout/grid/grid_extensions.dart';
import '../../../ui/base/text/surface_text.dart';
import 'sidebar_metrics.dart';
import 'sidebar_room.dart';
import 'sidebar_surface.dart';
import 'sidebar_tile.dart';

class SidebarView extends StatefulWidget {
  const SidebarView({super.key});

  @override
  State<SidebarView> createState() => _SidebarViewState();
}

class _SidebarViewState extends State<SidebarView>
    with SingleTickerProviderStateMixin {
  static const Duration _expandDuration = Duration(milliseconds: 350);

  String? _expandedZoneId;
  final Map<String, GlobalKey> _tileKeys = {};
  late final AnimationController _layoutRefreshController;

  final List<SidebarItemData> _items = [
    SidebarItemData(id: SidebarRoom.dashboardId, label: 'DashBoard', icon: Icons.dashboard_rounded),
    SidebarItemData(
      id: SidebarRoom.mediaId,
      label: 'media',
      icon: Icons.play_circle_outline_rounded,
      isZone: true,
      children: [
        SidebarItemData(id: SidebarRoom.movId, label: 'movie', icon: Icons.movie_filter_rounded),
        SidebarItemData(id: SidebarRoom.tvId, label: 'tvShow', icon: Icons.tv_rounded),
        SidebarItemData(id: SidebarRoom.aniId, label: 'Anime', icon: Icons.animation_rounded),
        SidebarItemData(id: SidebarRoom.docId, label: 'Documentary', icon: Icons.description_rounded),
        SidebarItemData(id: SidebarRoom.adtId, label: 'Adult', icon: Icons.explicit_rounded),
      ],
    ),
    SidebarItemData(
      id: SidebarRoom.musicId,
      label: 'music',
      icon: Icons.auto_stories_rounded,
      isZone: true,
      children: [
        SidebarItemData(id: SidebarRoom.gongId, label: '宫', icon: Icons.bookmark_rounded),
        SidebarItemData(id: SidebarRoom.shangId, label: '商', icon: Icons.bookmark_rounded),
        SidebarItemData(id: SidebarRoom.jiaoId, label: '角', icon: Icons.bookmark_rounded),
        SidebarItemData(id: SidebarRoom.zhiId, label: '徵', icon: Icons.bookmark_rounded),
        SidebarItemData(id: SidebarRoom.yuId, label: '羽', icon: Icons.bookmark_rounded),
      ],
    ),
    SidebarItemData(id: SidebarRoom.settingId, label: 'setting', icon: Icons.settings_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _layoutRefreshController = AnimationController(vsync: this, duration: _expandDuration)
      ..addListener(() { if (mounted) setState(() {}); });
    _registerKeys(_items);
    _tileKeys[SidebarRoom.exitId] = GlobalKey();
  }

  @override
  void dispose() {
    _layoutRefreshController.dispose();
    super.dispose();
  }

  void _registerKeys(List<SidebarItemData> items) {
    for (final item in items) {
      _tileKeys[item.id] = GlobalKey();
      if (item.children != null) _registerKeys(item.children!);
    }
  }

  Path? _calculateNotchPath(String? activeId) {
    if (activeId == null) return null;
    final activeKey = _tileKeys[activeId];
    final tileContext = activeKey?.currentContext;
    final surfaceBox = context.findRenderObject() as RenderBox?;
    final tileBox = tileContext?.findRenderObject() as RenderBox?;
    if (tileContext == null || surfaceBox == null || tileBox == null || !surfaceBox.hasSize || !tileBox.hasSize) return null;

    final localOffset = tileBox.localToGlobal(Offset.zero, ancestor: surfaceBox);
    final rect = Rect.fromLTRB(localOffset.dx, localOffset.dy, context.units(SidebarMetrics.widthU), localOffset.dy + tileBox.size.height);

    return SidebarTileFocusGeometry(
      borderRadius: BorderRadius.circular(context.units(SidebarMetrics.tileRadiusU)),
      openRightness: 1.0,
      concaveRadius: context.units(SidebarMetrics.surfaceRadiusU),
    ).buildCutoutPath(rect);
  }

  @override
  Widget build(BuildContext context) {
    // 监听全局焦点状态
    context.useIsActive('sidebar');
    
    String? currentActiveId;
    void findActive(List<SidebarItemData> items) {
      for (final item in items) {
        if (context.useIsActive(item.id)) {
          if (item.children == null || item.children!.isEmpty) {
            currentActiveId = item.id;
          } else {
            findActive(item.children!);
          }
        }
      }
    }
    findActive(_items);
    if (currentActiveId == null && context.useIsActive(SidebarRoom.exitId)) {
      currentActiveId = SidebarRoom.exitId;
    }

    // 兜底：如果完全没选中，默认给 Dashboard
    final String effectiveAutofocusId = currentActiveId ?? SidebarRoom.dashboardId;

    return ThemeIdentity(
      role: ThemeRole.sidebar,
      child: SidebarRoom(
        child: SizedBox(
          width: context.units(SidebarMetrics.widthU),
          child: SidebarSurface(
            roundLeft: false,
            notchPath: _calculateNotchPath(currentActiveId),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.units(SidebarMetrics.contentPaddingLeftU),
                context.units(SidebarMetrics.contentPaddingTopU),
                context.units(SidebarMetrics.contentPaddingRightU),
                context.units(SidebarMetrics.contentPaddingBottomU),
              ),
              child: Column(
                children: [
                  SizedBox(height: context.units(SidebarMetrics.brandTopGapU)),
                  const _SidebarBrandHeader(),
                  SizedBox(height: context.units(SidebarMetrics.headerItemsGapU)),
                  ..._items.map((item) => _buildItem(item, effectiveAutofocusId)),
                  const Spacer(),
                  _buildExitTile(effectiveAutofocusId),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExitTile(String autofocusId) {
    final bool isActive = context.useIsActive(SidebarRoom.exitId);
    return SidebarTile(
      key: _tileKeys[SidebarRoom.exitId],
      id: SidebarRoom.exitId,
      label: 'exit',
      icon: Icons.power_settings_new_rounded,
      isActive: isActive,
      autofocus: autofocusId == SidebarRoom.exitId, // 找回 autofocus
      onTap: () => FocusAPI.dispatchAction('sidebar', SidebarRoom.exitId),
    );
  }

  Widget _buildItem(SidebarItemData item, String autofocusId, {bool isChild = false}) {
    final isExpanded = _expandedZoneId == item.id;
    final hasChildren = item.children != null && item.children!.isNotEmpty;
    final bool isActive = context.useIsActive(item.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: context.units(SidebarMetrics.itemGapU),
            left: isChild ? context.units(1.6) : 0,
          ),
          child: SidebarTile(
            key: _tileKeys[item.id],
            id: item.id,
            label: item.label,
            icon: item.icon,
            isActive: isActive,
            autofocus: autofocusId == item.id, // 找回 autofocus
            onTap: () {
              if (hasChildren) {
                setState(() { _expandedZoneId = isExpanded ? null : item.id; });
                _layoutRefreshController.forward(from: 0);
              } else {
                FocusAPI.dispatchAction('sidebar', item.id);
              }
            },
          ),
        ),
        if (hasChildren)
          AnimatedSize(
            duration: _expandDuration,
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? SuperFocusRoom(
                    id: item.id,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: item.children!
                          .map((child) => _buildItem(child, autofocusId, isChild: true))
                          .toList(),
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
      ],
    );
  }
}

class SidebarItemData {
  final String id;
  final String label;
  final IconData icon;
  final List<SidebarItemData>? children;
  final bool isZone;
  SidebarItemData({required this.id, required this.label, required this.icon, this.children, this.isZone = false});
}

class _SidebarBrandHeader extends StatelessWidget {
  const _SidebarBrandHeader();
  @override
  Widget build(BuildContext context) {
    final radius = context.units(SidebarMetrics.brandPanelRadiusU);
    return ThemeIdentity(role: ThemeRole.sidebar, layer: ThemeLayer.under, child: SidebarSurface(radius: radius, child: Container(height: context.units(SidebarMetrics.brandHeaderHeightU), padding: EdgeInsets.symmetric(horizontal: context.units(SidebarMetrics.brandPanelPaddingHorizontalU)), child: ThemeIdentity(role: ThemeRole.sidebar, layer: ThemeLayer.base, child: Row(children: [Icon(Icons.blur_on_rounded, size: 36, color: context.useTheme().colors.accent), const SizedBox(width: 14), const Expanded(child: SurfaceText('Digital. Center', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1)))],))))) ;
  }
}
