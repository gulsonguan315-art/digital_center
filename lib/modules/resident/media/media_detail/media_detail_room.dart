import 'package:flutter/material.dart';
import 'package:superfocus/core/control/superfocus/interaction_state.dart';
import '../../../../core/control/superfocus/focus_api.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../../core/control/superfocus/focus_scroll_policy.dart';
import '../../../../core/layout/grid/grid.dart';
import 'core/media_detail_controller.dart';
import 'views_components/hero_metadata_view.dart';
import 'movie_detail_view.dart';
import 'series_detail_view.dart';

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
  late MediaDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MediaDetailController(widget.itemId);
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
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

            if (_controller.isLoading) {
              return Container(
                color: material.colors.surface,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (_controller.isError || _controller.rawDetails == null) {
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

            final backdropUrl = _controller.backdropUrl;

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
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
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
                                  HeroMetadataView(
                                    controller: _controller,
                                    roomId: widget.roomId,
                                    itemId: widget.itemId,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // 第二屏及以下：动态内容区
                          SliverToBoxAdapter(
                            child: _controller.type == 'Series'
                                ? SeriesDetailView(seriesId: widget.itemId, details: _controller.rawDetails!)
                                : MovieDetailView(controller: _controller),
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
}
