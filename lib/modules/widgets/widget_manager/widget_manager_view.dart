import 'package:flutter/material.dart';
import '../../../core/data/data_manager.dart';
import '../../../core/data/models/dashboard_item_config.dart';
import '../../../core/control/superfocus/focus_widgets.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../ui/base/text/surface_text.dart';
import '../../../ui/base/surface/dashboard_card.dart';
import '../../resident/dashboard/dashboard_model.dart';
import '../../resident/dashboard/engine/dashboard_grid_engine.dart';

/// 📂 挂件中控枢纽磁贴 (Widget Control Center Card Room)
/// 既是 Dashboard 上的一个 4x1 卡片，同时也是一个独立的 SuperFocus 子房间。
/// 焦点可以直接进入卡片内部，使用左右方向键在 6 个挂件开关之间流畅移动并点按开启/关闭。
class WidgetManagerView extends StatelessWidget {
  const WidgetManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuperFocusRoom(
      id: 'dash_widget_manager',
      child: _WidgetManagerPanel(),
    );
  }
}

class _WidgetManagerPanel extends StatelessWidget {
  const _WidgetManagerPanel();

  /// 可定制挂件静态元数据清单
  static List<DashboardCardMeta> get _cards =>
      DashboardModel.registry.where((c) => c.showInManager).toList();

  /// 切换挂件启用/禁用状态，并触发响应式写库与 SWR 同步
  void _toggleWidget(String id, List<DashboardItemConfig> currentConfigs) {
    final index = currentConfigs.indexWhere((c) => c.id == id);
    if (index != -1) {
      final oldItem = currentConfigs[index];
      final updated = oldItem.copyWith(enabled: !oldItem.enabled);
      
      var updatedList = List<DashboardItemConfig>.from(currentConfigs)
        ..[index] = updated;

      // 🌟 当更改启用状态时，重新运行网格重力沉降，使布局紧凑并避开潜在的位置重叠
      updatedList = DashboardGridEngine.applyGravity(updatedList);

      // 瞬间保存，主网格与控制面板同步响应式刷新
      DataManager.instance.saveDashboardItems(updatedList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.useTheme();
    final colors = theme.colors;

    return StreamBuilder<List<DashboardItemConfig>>(
      stream: DataManager.instance.watchDashboardItems(),
      initialData: DataManager.instance.latestLayout,
      builder: (context, snapshot) {
        final configs = snapshot.data ?? DataManager.instance.latestLayout;

        return DashboardCard(
          layer: ThemeLayer.base,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. 右下角微缩科技图标底纹 (Backdrop tech icon decoration)
              Positioned(
                bottom: -25,
                right: -15,
                child: Icon(
                  Icons.tune_rounded,
                  size: 90,
                  color: colors.accent.withValues(alpha: 0.05),
                ),
              ),

              // 2. 主体横向布局
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 左边栏：中控标志与健康度 (Left status panel)
                  Container(
                    width: 140,
                    padding: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: colors.accent.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 黄金齿轮图标
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.accent.withValues(alpha: 0.12),
                            border: Border.all(
                              color: colors.accent.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            size: 16,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SurfaceText(
                                '中控枢纽',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  _StatusDot(color: colors.accent),
                                  const SizedBox(width: 4),
                                  SurfaceText(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: colors.textSecondary.withValues(alpha: 0.6),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 右边栏：横向铺开的 6 个金色微缩开关芯片 (Horizontal IoT switches row)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _cards.map((card) {
                          // 从数据流中找出该挂件的启用状态，默认为 false
                          final isEnabled = configs
                              .firstWhere(
                                (c) => c.id == card.id,
                                orElse: () => DashboardItemConfig(
                                  id: card.id,
                                  x: 0,
                                  y: 0,
                                  spanX: 1,
                                  spanY: 1,
                                  enabled: false,
                                ),
                              )
                              .enabled;

                          // 🌟 将每一个开关芯片包装在 FocusIdentity 中，支持空间左右导航！
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: FocusIdentity(
                              id: 'switch_${card.id}',
                              onPressed: () {
                                _toggleWidget(card.id, configs);
                              },
                              builder: (context, hasFocus) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 106,
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasFocus
                                        ? colors.accent.withValues(alpha: 0.12)
                                        : (isEnabled
                                            ? colors.accent.withValues(alpha: 0.05)
                                            : colors.surface.withValues(alpha: 0.15)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: hasFocus
                                          ? colors.accent
                                          : (isEnabled
                                              ? colors.accent.withValues(alpha: 0.25)
                                              : colors.accent.withValues(alpha: 0.1)),
                                      width: hasFocus ? 1.8 : 1.0,
                                    ),
                                    boxShadow: hasFocus
                                        ? [
                                            BoxShadow(
                                              color: colors.accent.withValues(alpha: 0.12),
                                              blurRadius: 10,
                                              spreadRadius: 0.5,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // 挂件微缩图标
                                      Icon(
                                        card.icon,
                                        size: 16,
                                        color: isEnabled
                                            ? colors.accent
                                            : colors.textSecondary.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SurfaceText(
                                              card.title,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            // 极具质感的黄金状态点
                                            Row(
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isEnabled
                                                        ? colors.accent
                                                        : Colors.grey.withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                SurfaceText(
                                                  isEnabled ? '已开启' : '已隐藏',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    color: isEnabled
                                                        ? colors.accent
                                                        : colors.textSecondary.withValues(alpha: 0.4),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}



/// 呼吸状态绿灯
class _StatusDot extends StatefulWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value),
          ),
        );
      },
    );
  }
}
