import 'package:flutter/material.dart';
import 'package:superfocus/core/layout/grid/grid_extensions.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/control/superfocus/interaction_manager.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../media_model.dart';
import 'media_view.dart';
import '../media_service.dart';
import 'media_callback.dart';
import '../media_detail/media_detail_room.dart';
import '../../sidebar/sidebar_metrics.dart';
import '../../../../core/stage/stage_metrics.dart';

/// 📂 影视页面主房间 (Media Room - Composition Root)
class MediaRoom extends StatefulWidget {
  final Widget? child;
  const MediaRoom({super.key, this.child});

  static const String roomId = MediaModel.mediaPageId;

  @override
  State<MediaRoom> createState() => _MediaRoomState();
}

class _MediaRoomState extends State<MediaRoom> {
  bool _isDetailVisible = false;
  String? _activeDetailId;
  Widget? _detailWidgetCache;

  // 用于锁定 Stack 的坐标系
  final GlobalKey _stackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SuperFocusRoom(
      id: MediaModel.mediaPageId,
      child:
          widget.child ??
          ValueListenableBuilder<FocusTopology>(
            valueListenable: SuperFocusManager.instance.topologyNotifier,
            builder: (context, topology, _) {
              final isActive = topology.activePath.contains(
                MediaModel.mediaPageId,
              );
              final isEntering =
                  SuperFocusManager.instance.intentionRoomId.value ==
                  MediaModel.mediaPageId;

              // 页面不活跃且未在进入意图中，跳过渲染节省 GPU
              if (!isActive && !isEntering) {
                return const SizedBox.shrink();
              }

              // 判断是否在详情页
              final String? movieDetailId =
                  topology.activeRoom?.startsWith('movieDetail_') == true
                  ? topology.activeRoom!.replaceFirst('movieDetail_', '')
                  : null;
              final String? seriesDetailId =
                  topology.activeRoom?.startsWith('seriesDetail_') == true
                  ? topology.activeRoom!.replaceFirst('seriesDetail_', '')
                  : null;

              // 判断是否有合集展开
              String? expandedBoxSetId;
              for (final path in topology.activePath) {
                if (path.startsWith('mediaExpand_')) {
                  expandedBoxSetId = path.replaceFirst('mediaExpand_', '');
                  break;
                }
              }

              // 订阅 MediaService 状态（分类 / 条目列表 / 加载状态）
              return ListenableBuilder(
                listenable: MediaService.instance,
                builder: (context, _) {
                  final service = MediaService.instance;
                  final activeCategory = service.selectedCategory;

                  final gridView = MediaPageView(
                    key: const ValueKey('media_grid'),
                    category: activeCategory,
                    expandedBoxSetId: expandedBoxSetId,
                    gridItemSlot:
                        (context, item, innerBuilder, {onTapOverride}) {
                          final focusId = item.id;

                          void action(BuildContext ctx) {
                            final RenderBox? itemBox = ctx.findRenderObject() as RenderBox?;
                            if (itemBox != null) {
                              final itemGlobal = itemBox.localToGlobal(Offset.zero);
                              MediaService.instance.lastHeroRect = itemGlobal & itemBox.size;
                              MediaService.instance.lastHeroItem = item;
                            }

                            onTapOverride != null
                                ? onTapOverride()
                                : MediaCallback.onMediaPosterTap(
                                    ctx,
                                    item,
                                    expandedBoxSetId,
                                  );
                          }

                          return ThemeIdentity(
                            role: ThemeRole.card,
                            child: Builder(
                              builder: (context) {
                                final material = context.useTheme();
                                return FocusIdentity(
                                  id: focusId,
                                  onPressed: () => action(context),
                                  alignment: FocusAlignment.keepVisible,
                                  focusGeometry: RoundedRectFocusGeometry(
                                    borderRadius: material.shape.radius,
                                  ),
                                  builder: (ctx, hasFocus) => innerBuilder(
                                    ctx,
                                    hasFocus,
                                    () => action(ctx), // Pass the inner context
                                    item: item,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                  );

                  return Builder(
                    builder: (stackContext) {
                      // 提取当前详情页状态
                      final bool isDetailActive = movieDetailId != null || seriesDetailId != null;
                      
                      if (isDetailActive) {
                        _isDetailVisible = true;
                        _activeDetailId = movieDetailId ?? seriesDetailId;
                        _detailWidgetCache = seriesDetailId != null
                            ? MediaDetailRoom(
                                roomId: 'seriesDetail_$seriesDetailId',
                                itemId: seriesDetailId,
                              )
                            : MediaDetailRoom(
                                roomId: 'movieDetail_$movieDetailId',
                                itemId: movieDetailId!,
                              );
                      } else {
                        _isDetailVisible = false;
                        // 延迟清除缓存，等待退场动画播完 (500ms)
                        if (_detailWidgetCache != null) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted && !_isDetailVisible) {
                              setState(() {
                                _detailWidgetCache = null;
                              });
                            }
                          });
                        }
                      }

                      return Stack(
                        key: _stackKey,
                        clipBehavior: Clip.none,
                        children: [
                          // 底层海报墙：因为 StagePhysicalFrame 已经统一提供了左侧安全区，
                          // 这里不再需要手动加 Padding，直接渲染即可。
                          gridView,

                          // 顶层详情页覆盖 (全屏沉浸，支持双向 Hero 动画)
                          if (_detailWidgetCache != null)
                            Builder(builder: (context) {
                              // 全屏 Rect，必须抵消 StagePhysicalFrame 外壳引入的 padding
                              // 利用组合的负边距，逃脱全局的侧边栏安全区，重回物理屏幕左上角
                              final fullScreenRect = Rect.fromLTWH(
                                -context.units(StageMetrics.paddingHorizontalU + SidebarMetrics.widthU),
                                -context.units(StageMetrics.paddingVerticalU),
                                MediaQuery.sizeOf(context).width,
                                MediaQuery.sizeOf(context).height,
                              );

                              Rect startRect = Rect.fromCenter(
                                center: fullScreenRect.center,
                                width: fullScreenRect.width * 0.8,
                                height: fullScreenRect.height * 0.8,
                              );

                              final RenderBox? stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
                          
                          if (stackBox != null && MediaService.instance.lastHeroRect != null) {
                            final globalRect = MediaService.instance.lastHeroRect!;
                            final localOffset = stackBox.globalToLocal(globalRect.topLeft);
                            final baseRect = localOffset & globalRect.size;
                            
                            startRect = Rect.fromCenter(
                              center: baseRect.center,
                              width: baseRect.width * 1.05,
                              height: baseRect.height * 1.05,
                            );
                          }

                          // 根据可见状态决定目标 Rect
                          final targetRect = _isDetailVisible ? fullScreenRect : startRect;

                          return TweenAnimationBuilder<Rect?>(
                            key: ValueKey(_activeDetailId),
                            tween: RectTween(begin: startRect, end: targetRect),
                            // 恢复正常的 500ms 电影级转场速度
                            duration: const Duration(milliseconds: 500),
                            // 根据进出场状态动态切换缓动曲线
                            // 进场 (放大): 缓入缓出 (开始慢，中间快，结尾慢)
                            // 退场 (缩小): 加速退场 (开始慢，结束快)
                            curve: _isDetailVisible ? Curves.easeInOutCubic : Curves.easeInCubic,
                            builder: (context, rect, child) {
                              if (rect == null) return const SizedBox.shrink();
                              
                              // 计算动画进度用于文字渐显 (反向计算进度)
                              final progress = (rect.width - startRect.width) / 
                                  (fullScreenRect.width - startRect.width + 0.1); 
                                  
                              return Positioned.fromRect(
                                rect: rect,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    context.units(4) * (1 - progress.clamp(0.0, 1.0)),
                                  ),
                                  child: OverflowBox(
                                    minWidth: fullScreenRect.width,
                                    maxWidth: fullScreenRect.width,
                                    minHeight: fullScreenRect.height,
                                    maxHeight: fullScreenRect.height,
                                    alignment: Alignment.center,
                                    child: Transform.scale(
                                      scale: 0.9 + 0.1 * progress.clamp(0.0, 1.0),
                                      // 直接显示详情页，利用 ClipRRect 形成“遮罩展开”的电影级转场效果
                                      child: child,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: IgnorePointer(
                              ignoring: !_isDetailVisible,
                              child: _detailWidgetCache,
                            ),
                          );
                        }),
                    ],
                  );
                 },
                );
              },
            );
            },
          ),
    );
  }
}
