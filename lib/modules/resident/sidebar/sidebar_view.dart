import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';
import '../../../ui/base/text/surface_text.dart';
import 'sidebar_metrics.dart';
import 'sidebar_surface.dart';
import 'sidebar_model.dart';

/// 侧边栏视图 (纯排版工具 - 终极满分版)
/// 职责：
/// 1. 测量坐标、排版、缩进、运行展开动画。
/// 2. 它不关心逻辑，只管往“包工头”给的“逻辑结界（Wrapper）”里填砖头。
class SidebarView extends StatefulWidget {
  final Map<String, Widget> slots;
  final Map<String, Widget Function(Widget child)> zoneWrappers; // ✅ 升级为包装器函数
  final Widget? settingSlot; // 🌟 新增：设置插槽
  final Widget? exitSlot;
  final String? activeId;
  final String? expandedZoneId;

  const SidebarView({
    super.key,
    required this.slots,
    required this.zoneWrappers,
    this.settingSlot,
    this.exitSlot,
    this.activeId,
    this.expandedZoneId,
  });

  @override
  State<SidebarView> createState() => _SidebarViewState();
}

class _SidebarViewState extends State<SidebarView> {
  final Map<String, GlobalKey> _tileKeys = {};

  @override
  void initState() {
    super.initState();
    _refreshKeys();
  }

  @override
  void didUpdateWidget(SidebarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshKeys();
  }

  void _refreshKeys() {
    // 注册所有可能的 ID，确保测量正常
    void register(List<SidebarItemModel> items) {
      for (final item in items) {
        _tileKeys.putIfAbsent(item.id, () => GlobalKey());
        if (item.children != null) register(item.children!);
      }
    }
    register(SidebarModel.menuItems);
    _tileKeys.putIfAbsent(SidebarModel.settingId, () => GlobalKey());
    _tileKeys.putIfAbsent(SidebarModel.exitId, () => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    return ThemeIdentity(
      role: ThemeRole.sidebar,
      child: SizedBox(
        width: context.units(SidebarMetrics.widthU),
        child: SidebarSurface(
          roundLeft: false,
          activeRect: _calculateActiveRect(widget.activeId),
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
                
                ...SidebarModel.menuItems.map((item) => _buildLayoutTree(item)),

                const Spacer(),

                if (widget.settingSlot != null) ...[
                   KeyedSubtree(
                     key: _tileKeys[SidebarModel.settingId],
                     child: widget.settingSlot!,
                   ),
                   SizedBox(height: context.units(SidebarMetrics.itemGapU)),
                ],

                if (widget.exitSlot != null)
                   KeyedSubtree(
                     key: _tileKeys[SidebarModel.exitId],
                     child: widget.exitSlot!,
                   ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutTree(SidebarItemModel item, {int depth = 0}) {
    final hasChildren = item.children != null && item.children!.isNotEmpty;
    final isExpanded = widget.expandedZoneId == item.id;
    final nakedTile = widget.slots[item.id];

    if (nakedTile == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 父级 Tile (由 View 负责缩进和挂载 Key)
        Padding(
          padding: EdgeInsets.only(
            bottom: context.units(SidebarMetrics.itemGapU),
            left: depth > 0 ? context.units(1.6 * depth) : 0,
          ),
          child: KeyedSubtree(
            key: _tileKeys[item.id],
            child: nakedTile,
          ),
        ),

        // 2. 子菜单
        if (hasChildren)
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? _buildWrappedZone(item, depth: depth + 1)
                : const SizedBox(width: double.infinity, height: 0),
          ),
      ],
    );
  }

  /// 这里的精妙之处：View 负责排版子 Tile，从而能挂载 Key。
  /// 然后将排好的 UI 塞进包工头给的“结界（Wrapper）”里。
  Widget _buildWrappedZone(SidebarItemModel item, {int depth = 0}) {
    // 1. 泥瓦匠自己铺砖（生成子菜单 UI）
    final Widget childrenUI = Column(
      mainAxisSize: MainAxisSize.min,
      children: item.children!.map((child) => _buildLayoutTree(child, depth: depth)).toList(),
    );

    // 2. 向包工头申领“结界”进行包裹
    final wrapper = widget.zoneWrappers[item.id];
    return wrapper?.call(childrenUI) ?? childrenUI;
  }

  Rect? _calculateActiveRect(String? activeId) {
    if (activeId == null) return null;
    final activeKey = _tileKeys[activeId];
    final tileContext = activeKey?.currentContext;
    final surfaceBox = context.findRenderObject() as RenderBox?;
    final tileBox = tileContext?.findRenderObject() as RenderBox?;
    if (tileContext == null || surfaceBox == null || tileBox == null || !surfaceBox.hasSize || !tileBox.hasSize) return null;

    final localOffset = tileBox.localToGlobal(Offset.zero, ancestor: surfaceBox);
    return Rect.fromLTRB(
      localOffset.dx, // ✅ 自动包含左边距和缩进，让子菜单的缺口自动向右移
      localOffset.dy, 
      context.units(SidebarMetrics.widthU), 
      localOffset.dy + tileBox.size.height
    );
  }
}

class _SidebarBrandHeader extends StatelessWidget {
  const _SidebarBrandHeader();
  @override
  Widget build(BuildContext context) {
    final radius = context.units(SidebarMetrics.brandPanelRadiusU);
    return ThemeIdentity(
      role: ThemeRole.sidebar,
      layer: ThemeLayer.under,
      child: SidebarSurface(
        radius: radius,
        child: Container(
          height: context.units(SidebarMetrics.brandHeaderHeightU),
          padding: EdgeInsets.symmetric(
            horizontal: context.units(SidebarMetrics.brandPanelPaddingHorizontalU),
          ),
          child: ThemeIdentity(
            role: ThemeRole.sidebar,
            layer: ThemeLayer.base,
            child: Row(
              children: [
                Icon(
                  Icons.blur_on_rounded,
                  size: context.units(SidebarMetrics.brandBadgeIconSizeU),
                  color: context.useTheme().colors.accent,
                ),
                SizedBox(width: context.units(SidebarMetrics.brandBadgeGapU)),
                Expanded(
                  child: SurfaceText(
                    'Digital. Center',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: context.units(SidebarMetrics.brandTitleSizeU),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
