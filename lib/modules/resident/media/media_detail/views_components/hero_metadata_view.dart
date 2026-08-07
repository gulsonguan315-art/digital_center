import 'package:flutter/material.dart';
import '../../../../../core/engine/theme/theme_api.dart';
import '../../../../../core/layout/grid/grid.dart';
import '../../../../../core/control/superfocus/focus_api.dart';
import 'package:superfocus/core/control/superfocus/widgets/focus_widgets.dart';
import 'package:superfocus/core/control/superfocus/core/interaction_manager.dart';
import '../../media_service.dart';
import '../core/media_detail_controller.dart';

class HeroMetadataView extends StatelessWidget {
  final MediaDetailController controller;
  final String roomId;
  final String itemId;

  const HeroMetadataView({
    super.key,
    required this.controller,
    required this.roomId,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));
    final isActive = RoomScope.of(context)?.isActive ?? true;

    final title = controller.title;
    final logoUrl = controller.logoUrl;
    final year = controller.year;
    final rating = controller.rating;
    final runtimeStr = controller.runtimeStr;
    final genres = controller.genres;
    final overview = controller.overview;

    return Positioned(
      left:
          grid.pageInset +
          context.units(8.0), // 补偿负边距，同时避开折叠侧边栏(5.6U)和焦点环(17px)
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
              errorBuilder: (context, error, stackTrace) =>
                  _buildTitleText(title, grid, material),
            )
          else
            _buildTitleText(title, grid, material),

          SizedBox(height: grid.units(2)),

          // 元数据行
          DefaultTextStyle(
            style: TextStyle(
              fontSize: grid.units(2.2),
              color: material.colors.textSecondary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
            child: Wrap(
              spacing: grid.units(1.5),
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (year != null) Text(year.toString()),
                if (year != null) const _Dot(),
                if (rating != null) Text('★ ${rating.toStringAsFixed(1)}'),
                if (rating != null) const _Dot(),
                if (runtimeStr != null) Text(runtimeStr),
                if (runtimeStr != null) const _Dot(),
                if (genres != null && genres.isNotEmpty) Text(genres),
              ],
            ),
          ),

          SizedBox(height: grid.units(3)),

          // 剧情简介
          if (overview.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: grid.units(4)), // 留出右侧边距提升阅读体验
              child: Text(
                overview,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: grid.units(1.8),
                  color: material.colors.textSecondary,
                  height: 1.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ),

          SizedBox(height: grid.units(4)),

          // 操作按钮组
          Wrap(
            spacing: grid.units(2),
            runSpacing: grid.units(2),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildActionButton(
                context: context,
                grid: grid,
                material: material,
                id: 'btn_resume',
                icon: Icons.play_arrow_rounded,
                label: '续播',
                autofocus: isActive,
                isPrimary: true,
                onPressed: () async {
                  SuperInteractionManager.instance.setCursorWaiting(true);
                  final data = await controller.resolvePlaybackData(
                    fromBeginning: false,
                  );
                  SuperInteractionManager.instance.setCursorWaiting(false);

                  if (data == null || !context.mounted) return;

                  final targetItemId = data['id'] as String;
                  final ticks = data['ticks'] as int;

                  MediaService.instance.immersiveParams = MediaImmersiveParams(
                    itemId: targetItemId,
                    mediaType: controller.type == 'Series' ? 'Episode' : controller.type,
                    startPositionTicks: ticks,
                  );
                  FocusAPI.dispatchAction(roomId, 'media_overlay');
                },
              ),
              _buildActionButton(
                context: context,
                grid: grid,
                material: material,
                id: 'btn_play',
                icon: Icons.play_circle_outline_rounded,
                label: '播放',
                autofocus: false,
                isPrimary: false,
                onPressed: () async {
                  SuperInteractionManager.instance.setCursorWaiting(true);
                  final data = await controller.resolvePlaybackData(
                    fromBeginning: true,
                  );
                  SuperInteractionManager.instance.setCursorWaiting(false);

                  if (data == null || !context.mounted) return;

                  final targetItemId = data['id'] as String;

                  MediaService.instance.immersiveParams = MediaImmersiveParams(
                    itemId: targetItemId,
                    mediaType: controller.type == 'Series' ? 'Episode' : controller.type,
                    startPositionTicks: 0,
                    forceStartOver: true,
                  );
                  FocusAPI.dispatchAction(roomId, 'media_overlay');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleText(
    String title,
    GridContext grid,
    ResolvedThemeMaterial material,
  ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: grid.units(6),
        fontWeight: FontWeight.w900,
        color: material.colors.textPrimary,
        height: 1.1,
        letterSpacing: -0.5,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required GridContext grid,
    required ResolvedThemeMaterial material,
    required String id,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool autofocus = false,
    bool isPrimary = false,
  }) {
    return FocusIdentity(
      id: id,
      autofocus: autofocus,
      onPressed: onPressed,
      focusGeometry: RoundedRectFocusGeometry(
        borderRadius: BorderRadius.circular(grid.units(4)),
      ),
      builder: (context, hasFocus) {
        final bgColor = hasFocus
            ? material.colors.textPrimary
            : (isPrimary
                  ? material.colors.textPrimary.withValues(alpha: 0.8)
                  : material.colors.foreground.withValues(alpha: 0.5));

        final fgColor = hasFocus
            ? material.colors.surface
            : (isPrimary
                  ? material.colors.surface
                  : material.colors.textPrimary);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: grid.units(3.5),
            vertical: grid.units(1.2),
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(grid.units(4)),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: material.colors.textPrimary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fgColor, size: grid.units(2.8)),
              SizedBox(width: grid.units(1)),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: grid.units(2.2),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
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
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: context.useTheme().colors.textSecondary.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}
