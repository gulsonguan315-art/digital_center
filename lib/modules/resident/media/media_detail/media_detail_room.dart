import 'package:flutter/material.dart';
import 'package:superfocus/core/control/superfocus/interaction_state.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../../core/control/superfocus/focus_scroll_policy.dart';
import '../../../../core/layout/grid/grid.dart';
import '../media_service.dart';
import 'movie_detail_view.dart';
import 'series_detail_view.dart';
import '../../../overlay/media/media_immersive_overlay.dart';

class MediaDetailRoom extends StatefulWidget {
  final String roomId;
  final String itemId;

  const MediaDetailRoom({
    super.key,
    required this.roomId,
    required this.itemId,
  });

  @override
  State<MediaDetailRoom> createState() => _MediaDetailRoomState();
}

class _MediaDetailRoomState extends State<MediaDetailRoom> {
  Map<String, dynamic>? _details;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final details = await MediaService.instance.fetchItemDetails(widget.itemId);
    if (mounted) {
      setState(() {
        _details = details;
        _isLoading = false;
        _isError = details == null;
      });
    }
  }

  String? get _backdropTag {
    if (_details == null) return null;
    final tags = _details!['BackdropImageTags'] as List<dynamic>?;
    if (tags != null && tags.isNotEmpty) {
      return tags.first.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // 注册动态子房间
    return SuperFocusRoom(
      id: widget.roomId,
      transitionConfig: const FocusTransitionConfig(
        FocusTransitionMode.teleport,
        delay: Duration(milliseconds: 500),
      ),
      child: ThemeIdentity(
        role: ThemeRole.appBackground,
        child: Builder(
          builder: (context) {
            final material = context.useTheme();
            final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));

            if (_isLoading) {
              return Container(
                color: material.colors.surface,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (_isError || _details == null) {
              return Container(
                color: material.colors.surface,
                child: Center(
                  child: Text(
                    'Failed to load details.',
                    style: TextStyle(color: material.colors.textPrimary),
                  ),
                ),
              );
            }

            final title = _details!['Name'] as String? ?? 'Unknown';
            final year = _details!['ProductionYear'] as int?;
            final rating = (_details!['CommunityRating'] as num?)?.toDouble();
            final overview = _details!['Overview'] as String? ?? '';
            final genres = (_details!['Genres'] as List<dynamic>?)?.join(' / ');
            final runTimeTicks = _details!['RunTimeTicks'] as int?;
            String? runtimeStr;
            if (runTimeTicks != null) {
              final mins = runTimeTicks ~/ 60000000; // Ticks to minutes
              runtimeStr = '${mins ~/ 60}h ${mins % 60}m';
            }

            final backdropUrl = MediaService.instance.backdropUrl(
              widget.itemId,
              _backdropTag,
            );

            final imageTags = _details!['ImageTags'] as Map<String, dynamic>? ?? {};
            final logoTag = imageTags['Logo'] as String?;
            final logoUrl = logoTag != null ? MediaService.instance.logoUrl(widget.itemId, logoTag) : '';

            return Container(
              color: material.colors.surface,
              child: Stack(
                children: [
                  // 1. 全屏背景图
                  if (backdropUrl.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        backdropUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),

                  // 2. 电影级双层渐变蒙版
                  // 垂直渐变：确保底部深色，顶部透明
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            material.colors.surface.withValues(alpha: 0.6),
                            material.colors.surface,
                          ],
                          stops: const [0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // 水平渐变：确保左侧文本可读
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.transparent,
                            material.colors.surface.withValues(alpha: 0.8),
                            material.colors.surface,
                          ],
                          stops: const [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. 内容滚动区 (CustomScrollView)
                  Positioned.fill(
                    child: FocusScrollPolicy(
                      boundary: FocusScrollBoundary(
                        left: grid.pageInset + context.units(8.0),
                        right: grid.units(6),
                        top: context.units(8.0),
                        bottom: context.units(8.0),
                      ),
                      child: CustomScrollView(
                        cacheExtent: 1000.0,
                        slivers: [
                        // 第一屏：Hero Section (与物理屏幕等高)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: grid.pageInset + context.units(8.0), // 补偿负边距，同时避开折叠侧边栏(5.6U)和焦点环(17px)
                                  bottom: grid.units(10) + context.units(8.0), // 补偿负边距
                                  width: grid.viewportWidth * 0.5, // 占据半屏宽度
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 标题或 Logo
                                      if (logoUrl.isNotEmpty)
                                        Image.network(
                                          logoUrl,
                                          height: grid.units(12), // 苹果风格的 Logo 通常较大
                                          fit: BoxFit.contain,
                                          alignment: Alignment.centerLeft,
                                          errorBuilder: (context, error, stackTrace) => Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: grid.units(6),
                                              fontWeight: FontWeight.w900,
                                              color: material.colors.textPrimary,
                                              height: 1.1,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: grid.units(6),
                                            fontWeight: FontWeight.w900,
                                            color: material.colors.textPrimary,
                                            height: 1.1,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      SizedBox(height: grid.units(2)),

                                      // 元数据行
                                      DefaultTextStyle(
                                        style: TextStyle(
                                          fontSize: grid.units(2.2),
                                          color: material.colors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        child: Wrap(
                                          spacing: grid.units(1.5),
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            if (year != null) Text(year.toString()),
                                            if (year != null) const _Dot(),
                                            if (rating != null)
                                              Text('★ ${rating.toStringAsFixed(1)}'),
                                            if (rating != null) const _Dot(),
                                            if (runtimeStr != null) Text(runtimeStr),
                                            if (runtimeStr != null) const _Dot(),
                                            if (genres != null && genres.isNotEmpty)
                                              Text(genres),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: grid.units(3)),

                                      // 剧情简介
                                      if (overview.isNotEmpty)
                                        SizedBox(
                                          width: grid.viewportWidth * 0.45, // 简介文本略窄，提升阅读体验
                                          child: Text(
                                            overview,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: grid.units(1.8),
                                              color: material.colors.textSecondary,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),

                                      SizedBox(height: grid.units(4)),

                                      // 操作按钮组
                                      Row(
                                        children: [
                                          _buildActionButton(
                                            context: context,
                                            grid: grid,
                                            id: 'media_btn_play',
                                            icon: Icons.play_arrow_rounded,
                                            label: '播放',
                                            autofocus: true,
                                            isPrimary: true,
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                PageRouteBuilder(
                                                  opaque: true, // 阻止底层渲染
                                                  transitionDuration: const Duration(milliseconds: 400),
                                                  reverseTransitionDuration: const Duration(milliseconds: 300),
                                                  pageBuilder: (ctx, anim1, anim2) => FadeTransition(
                                                    opacity: anim1,
                                                    child: ScaleTransition(
                                                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                                                        CurvedAnimation(
                                                          parent: anim1,
                                                          curve: Curves.easeOutCubic,
                                                          reverseCurve: Curves.easeInCubic,
                                                        ),
                                                      ),
                                                      child: MediaImmersiveOverlay(itemId: widget.itemId),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          SizedBox(width: grid.units(2)),
                                          _buildActionButton(
                                            context: context,
                                            grid: grid,
                                            id: 'btn_trailer',
                                            icon: Icons.movie_creation_outlined,
                                            label: '预告片',
                                            onPressed: () {
                                              // TODO: 预告片逻辑
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // 第二屏及以下：动态内容区
                        SliverToBoxAdapter(
                          child: _details!['Type'] == 'Series'
                              ? SeriesDetailView(seriesId: widget.itemId, details: _details!)
                              : MovieDetailView(details: _details!),
                        ),
                        
                        // 底部留白
                        SliverToBoxAdapter(child: SizedBox(height: grid.units(10))),
                      ],
                    ),
                  ),
                ), // End Positioned.fill
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required GridContext grid,
    required String id,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool autofocus = false,
    bool isPrimary = false,
  }) {
    final material = context.useTheme();
    final radius = BorderRadius.circular(grid.units(4));

    return FocusIdentity(
      id: id,
      autofocus: autofocus,
      alignment: FocusAlignment.viewportStart,
      onPressed: onPressed,
      focusGeometry: RoundedRectFocusGeometry(borderRadius: radius),
      builder: (context, hasFocus) {
        // 核心交互动画状态
        final bgColor = isPrimary
            ? material.colors.textPrimary
            : material.colors.surface.withValues(alpha: 0.5);
        final textColor = isPrimary
            ? material.colors.surface
            : material.colors.textPrimary;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: grid.units(4),
            vertical: grid.units(1.5),
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : material.colors.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: grid.units(3.5)),
              SizedBox(width: grid.units(1)),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: grid.units(2.2),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));
    return Container(
      width: grid.units(0.6),
      height: grid.units(0.6),
      decoration: BoxDecoration(
        color: context.useTheme().colors.textSecondary.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}
