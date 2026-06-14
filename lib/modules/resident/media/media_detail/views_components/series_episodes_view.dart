import 'package:flutter/material.dart';
import '../../../../../core/engine/theme/theme_api.dart';
import '../../../../../core/layout/grid/grid.dart';
import '../../../../../core/control/superfocus/focus_api.dart';
import '../../../../../core/control/superfocus/focus_widgets.dart';
import '../../media_service.dart';
import '../../../../overlay/media/media_immersive_overlay.dart';

class SeriesEpisodesView extends StatefulWidget {
  final List<Map<String, dynamic>> episodes;
  final bool isLoading;

  const SeriesEpisodesView({
    super.key,
    required this.episodes,
    this.isLoading = false,
  });

  @override
  State<SeriesEpisodesView> createState() => _SeriesEpisodesViewState();
}

class _SeriesEpisodesViewState extends State<SeriesEpisodesView> {
  int _currentEpisodePage = 0;
  String _focusedEpisodeTitle = '';

  @override
  void didUpdateWidget(SeriesEpisodesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episodes != widget.episodes) {
      _currentEpisodePage = 0;
      _focusedEpisodeTitle = '';
    }
  }

  void _openEpisode(BuildContext context, String id) {
    final roomId = RoomScope.of(context)?.roomId ?? '';
    MediaService.instance.immersiveParams = MediaImmersiveParams(itemId: id);
    FocusAPI.dispatchAction(roomId, 'media_overlay');
  }

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));

    if (widget.isLoading) {
      return SizedBox(
        height: grid.units(20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.episodes.length <= 50) {
      return _buildThumbnailEpisodes(material, grid);
    } else {
      return _buildGridEpisodes(material, grid);
    }
  }

  Widget _buildThumbnailEpisodes(ResolvedThemeMaterial material, GridContext grid) {
    return Padding(
      padding: EdgeInsets.only(top: grid.units(3)),
      child: SizedBox(
        height: grid.units(23),
        child: FocusCluster(
          child: ListView.separated(
            padding: EdgeInsets.only(
              left: grid.pageInset + context.units(8.0),
              right: grid.units(6),
            ),
            scrollDirection: Axis.horizontal,
            cacheExtent: 1000.0,
            itemCount: widget.episodes.length,
            separatorBuilder: (context, index) => SizedBox(width: grid.units(3)),
            itemBuilder: (context, index) {
              final episode = widget.episodes[index];
              final id = episode['Id'] as String?;
              final name = episode['Name'] as String? ?? 'Episode';
              final epNumber = episode['IndexNumber'] as int?;
              final tag = (episode['ImageTags'] as Map?)?['Primary'] as String?;

              String imageUrl = '';
              if (id != null && tag != null) {
                imageUrl = MediaService.instance.posterUrl(id, tag);
              }

              return FocusIdentity(
                id: 'episode_$id',
                alignment: FocusAlignment.keepVisible,
                onPressed: () {
                  if (id != null) _openEpisode(context, id);
                },
                focusGeometry: RoundedRectFocusGeometry(
                  borderRadius: BorderRadius.circular(grid.units(1.5)),
                ),
                builder: (context, hasFocus) {
                  return SizedBox(
                    width: grid.units(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail (Landscape)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: grid.units(32),
                          height: grid.units(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(grid.units(1.5)),
                            border: Border.all(
                              color: hasFocus ? material.colors.accent : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: hasFocus
                                ? [
                                    BoxShadow(
                                      color: material.colors.accent.withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(grid.units(1.5) - 3),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildPlaceholder(material),
                                  )
                                : _buildPlaceholder(material),
                          ),
                        ),
                        SizedBox(height: grid.units(1.5)),
                        // Title
                        Text(
                          epNumber != null ? '$epNumber. $name' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: grid.units(1.8),
                            fontWeight: FontWeight.bold,
                            color: material.colors.textPrimary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGridEpisodes(ResolvedThemeMaterial material, GridContext grid) {
    final int totalPages = (widget.episodes.length / 50).ceil();
    final int startIdx = _currentEpisodePage * 50;
    final int endIdx = (startIdx + 50).clamp(0, widget.episodes.length);
    final pageEpisodes = widget.episodes.sublist(startIdx, endIdx);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pagination Picker
        SizedBox(
          height: grid.units(4),
          child: FocusCluster(
            child: ListView.separated(
              padding: EdgeInsets.only(
                left: grid.pageInset + context.units(8.0),
                right: grid.units(6),
              ),
              scrollDirection: Axis.horizontal,
              itemCount: totalPages,
              separatorBuilder: (context, index) => SizedBox(width: grid.units(1.5)),
              itemBuilder: (context, index) {
                final isSelected = index == _currentEpisodePage;
                final startRange = index * 50 + 1;
                final endRange = ((index + 1) * 50).clamp(1, widget.episodes.length);
                final label = '${startRange.toString().padLeft(3, '0')}-${endRange.toString().padLeft(3, '0')}';

                return FocusIdentity(
                  id: 'ep_page_$index',
                  alignment: FocusAlignment.top,
                  onPressed: () {
                    if (index != _currentEpisodePage) {
                      setState(() {
                        _currentEpisodePage = index;
                      });
                    }
                  },
                  focusGeometry: RoundedRectFocusGeometry(
                    borderRadius: BorderRadius.circular(grid.units(2.0)),
                  ),
                  builder: (context, hasFocus) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: grid.units(1.5)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: material.colors.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(grid.units(2.0)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: grid.units(1.5),
                          fontWeight: FontWeight.w600,
                          color: isSelected || hasFocus ? material.colors.accent : material.colors.textPrimary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),

        SizedBox(height: grid.units(2)),

        // Focused Episode Title Area
        SizedBox(
          height: grid.units(3),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: grid.pageInset + context.units(8.0)),
            child: Text(
              _focusedEpisodeTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: grid.units(2.0),
                fontWeight: FontWeight.bold,
                color: material.colors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),

        SizedBox(height: grid.units(2)),

        // Episodes Grid
        Padding(
          padding: EdgeInsets.symmetric(horizontal: grid.pageInset + context.units(8.0)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double spacing = grid.units(1.5);
              // Subtract a tiny amount to prevent floating point precision overflow
              final double itemWidth = (constraints.maxWidth - (9 * spacing) - 0.1) / 10;
              final double itemHeight = itemWidth / 1.5;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(50, (index) {
                  if (index >= pageEpisodes.length) {
                    return SizedBox(width: itemWidth, height: itemHeight);
                  }
                  final episode = pageEpisodes[index];
                  final id = episode['Id'] as String?;
                  final name = episode['Name'] as String? ?? 'Episode';
                  final epNumber = episode['IndexNumber'] as int?;
                  final displayTitle = epNumber != null ? '$epNumber. $name' : name;
                  final label = epNumber?.toString() ?? '${startIdx + index + 1}';

                  return SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: FocusIdentity(
                      id: 'episode_grid_$id',
                      alignment: FocusAlignment.keepVisible,
                      onPressed: () {
                        if (id != null) _openEpisode(context, id);
                      },
                      focusGeometry: RoundedRectFocusGeometry(
                        borderRadius: BorderRadius.circular(grid.units(1.0)),
                      ),
                      builder: (context, hasFocus) {
                        if (hasFocus && _focusedEpisodeTitle != displayTitle) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _focusedEpisodeTitle = displayTitle;
                              });
                            }
                          });
                        }

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: material.colors.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(grid.units(1.0)),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: grid.units(1.6),
                              fontWeight: FontWeight.bold,
                              color: hasFocus ? material.colors.accent : material.colors.textPrimary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ResolvedThemeMaterial material) {
    return Container(
      color: material.colors.foreground,
      child: Center(
        child: Icon(
          Icons.tv,
          color: material.colors.textSecondary,
          size: 40,
        ),
      ),
    );
  }
}
