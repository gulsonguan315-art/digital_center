import 'package:flutter/material.dart';
import '../../../core/control/superfocus/focus_manager.dart';
import '../../../core/control/superfocus/focus_geometry.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import 'sidebar_metrics.dart';
import 'sidebar_surface.dart';
import 'sidebar_tile.dart';
import 'sidebar_room.dart';

class SidebarView extends StatefulWidget {
  const SidebarView({super.key});

  @override
  State<SidebarView> createState() => _SidebarViewState();
}

class _SidebarViewState extends State<SidebarView> {
  String _activeId = SidebarRoom.dashboardId;
  String? _expandedZoneId; // 当前展开的区域 ID
  final Map<String, GlobalKey> _tileKeys = {};

  final List<SidebarItemData> _items = [
    SidebarItemData(
      id: SidebarRoom.dashboardId,
      label: 'DashBoard',
      icon: Icons.dashboard_rounded,
    ),
    SidebarItemData(
      id: SidebarRoom.mediaId,
      label: 'media',
      icon: Icons.play_circle_outline_rounded,
      isZone: true,
      children: [
        SidebarItemData(
          id: SidebarRoom.movId,
          label: 'movie',
          icon: Icons.movie_filter_rounded,
        ),
        SidebarItemData(
          id: SidebarRoom.tvId,
          label: 'tvShow',
          icon: Icons.tv_rounded,
        ),
        SidebarItemData(
          id: SidebarRoom.aniId,
          label: 'Anime',
          icon: Icons.animation_rounded,
        ),
        SidebarItemData(
          id: SidebarRoom.docId,
          label: 'Documentary',
          icon: Icons.description_rounded,
        ),
        SidebarItemData(
          id: SidebarRoom.adtId,
          label: 'Adult',
          icon: Icons.explicit_rounded,
        ),
      ],
    ),
    SidebarItemData(
      id: SidebarRoom.musicId,
      label: 'music',
      icon: Icons.auto_stories_rounded,
      isZone: true,
      children: [
        SidebarItemData(
          id: SidebarRoom.gongId,
          label: '宫',
          icon: Icons.bookmark_rounded,
        ),
        SidebarItemData(
          id: SidebarRoom.shangId,
          label: '商',
          icon: Icons.bookmark_rounded,
        ),
        SidebarItemData(
          id: SidebarRoom.jiaoId,
          label: '角',
          icon: Icons.bookmark_rounded,
        ),
        SidebarItemData(
          id: SidebarRoom.zhiId,
          label: '徵',
          icon: Icons.bookmark_rounded,
        ),
        SidebarItemData(
          id: SidebarRoom.yuId,
          label: '羽',
          icon: Icons.bookmark_rounded,
        ),
      ],
    ),
    SidebarItemData(
      id: SidebarRoom.settingId,
      label: 'setting',
      icon: Icons.settings_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _registerKeys(_items);
    _tileKeys[SidebarRoom.exitId] = GlobalKey();
  }

  void _registerKeys(List<SidebarItemData> items) {
    for (var item in items) {
      _tileKeys[item.id] = GlobalKey();
      if (item.children != null) {
        _registerKeys(item.children!);
      }
    }
  }

  bool _isLeafId(String id) {
    if (id == SidebarRoom.exitId) return true;
    bool visit(List<SidebarItemData> items) {
      for (final item in items) {
        final hasChildren = item.children != null && item.children!.isNotEmpty;
        if (item.id == id) return !hasChildren;
        if (hasChildren && visit(item.children!)) return true;
      }
      return false;
    }

    return visit(_items);
  }

  Path? _calculateNotchPath() {
    if (!_isLeafId(_activeId)) return null;

    final activeKey = _tileKeys[_activeId];
    final tileContext = activeKey?.currentContext;
    final surfaceBox = context.findRenderObject() as RenderBox?;
    final tileBox = tileContext?.findRenderObject() as RenderBox?;

    if (tileContext == null ||
        surfaceBox == null ||
        tileBox == null ||
        !surfaceBox.hasSize ||
        !tileBox.hasSize) {
      return null;
    }

    final localOffset = tileBox.localToGlobal(
      Offset.zero,
      ancestor: surfaceBox,
    );

    final rect = Rect.fromLTRB(
      localOffset.dx,
      localOffset.dy,
      SidebarMetrics.width,
      localOffset.dy + tileBox.size.height,
    );

    final geometry = SidebarTileFocusGeometry(
      borderRadius: BorderRadius.circular(SidebarMetrics.tileRadius),
      openRightness: 1.0,
      concaveRadius: SidebarMetrics.surfaceRadius,
    );

    return geometry.buildCutoutPath(rect);
  }

  @override
  Widget build(BuildContext context) {
    // 监听全局拓扑：当焦点在侧边栏内部切换时，通知 SidebarSurface 更新缺口位置
    return ValueListenableBuilder<FocusTopology>(
      valueListenable: SuperFocusManager.instance.topologyNotifier,
      builder: (context, topology, _) {
        return SidebarRoom(
          child: SidebarSurface(
            notchPath: _calculateNotchPath(),
            child: Container(
              width: SidebarMetrics.width,
              padding: SidebarMetrics.contentPadding,
              child: Column(
                children: [
                  const SizedBox(height: SidebarMetrics.brandTopGap),
                  _SidebarBrandHeader(),
                  const SizedBox(height: SidebarMetrics.headerItemsGap),
                  ..._items.map(_buildItem),
                  const Spacer(),
                  SidebarTile(
                    key: _tileKeys[SidebarRoom.exitId],
                    id: SidebarRoom.exitId,
                    label: 'exit',
                    icon: Icons.power_settings_new_rounded,
                    isActive: _activeId == SidebarRoom.exitId,
                    autofocus: _activeId == SidebarRoom.exitId,
                    onTap: () {
                      setState(() {
                        _activeId = SidebarRoom.exitId;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(SidebarItemData item, {bool isChild = false}) {
    final bool isExpanded = _expandedZoneId == item.id;
    final bool hasChildren = item.children != null && item.children!.isNotEmpty;
    final bool isLeaf = !hasChildren;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: SidebarMetrics.itemGap,
            left: isChild ? 16 : 0,
          ),
          child: SidebarTile(
            key: _tileKeys[item.id],
            id: item.id,
            label: item.label,
            icon: item.icon,
            isActive: isLeaf && _activeId == item.id,
            autofocus: _activeId == item.id,
            onTap: () {
              setState(() {
                if (hasChildren) {
                  _expandedZoneId = item.id;
                } else {
                  _activeId = item.id;
                }
              });
            },
          ),
        ),
        if (hasChildren && isExpanded)
          SuperFocusRoom(
            id: item.id,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: item.children!
                  .map((child) => _buildItem(child, isChild: true))
                  .toList(),
            ),
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

  SidebarItemData({
    required this.id,
    required this.label,
    required this.icon,
    this.children,
    this.isZone = false,
  });
}

class _SidebarBrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: SidebarMetrics.brandHeaderHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: SidebarMetrics.brandPanelPaddingHorizontal,
        vertical: SidebarMetrics.brandPanelPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(SidebarMetrics.brandPanelRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.blur_on_rounded, size: 32, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Digital',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'CENTER',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
