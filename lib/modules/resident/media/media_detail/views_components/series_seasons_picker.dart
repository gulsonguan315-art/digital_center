import 'package:flutter/material.dart';
import '../../../../../core/engine/theme/theme_api.dart';
import '../../../../../core/layout/grid/grid.dart';
import '../../../../../core/control/superfocus/focus_api.dart';

class SeriesSeasonsPicker extends StatelessWidget {
  final List<Map<String, dynamic>> seasons;
  final String? selectedSeasonId;
  final ValueChanged<String> onSeasonSelected;

  const SeriesSeasonsPicker({
    super.key,
    required this.seasons,
    required this.selectedSeasonId,
    required this.onSeasonSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) return const SizedBox.shrink();

    final material = context.useTheme();
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));

    return SizedBox(
      height: grid.units(5),
      child: FocusCluster(
        child: ListView.separated(
          padding: EdgeInsets.only(
            left: grid.pageInset + context.units(8.0),
            right: grid.units(6),
          ),
          scrollDirection: Axis.horizontal,
          cacheExtent: 1000.0,
          itemCount: seasons.length,
          separatorBuilder: (context, index) => SizedBox(width: grid.units(2)),
          itemBuilder: (context, index) {
            final season = seasons[index];
            final id = season['Id'] as String?;
            final name = season['Name'] as String? ?? 'Season';
            final isSelected = id == selectedSeasonId;

            return FocusIdentity(
              id: 'season_$id',
              alignment: FocusAlignment.top,
              onPressed: () {
                if (id != null && id != selectedSeasonId) {
                  onSeasonSelected(id);
                }
              },
              focusGeometry: RoundedRectFocusGeometry(
                borderRadius: BorderRadius.circular(grid.units(2.5)),
              ),
              builder: (context, hasFocus) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: grid.units(2)),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: material.colors.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(grid.units(2.5)),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: grid.units(1.8),
                      fontWeight: FontWeight.w600,
                      color: isSelected || hasFocus
                          ? material.colors.accent
                          : material.colors.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
