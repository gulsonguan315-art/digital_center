import 'package:flutter/material.dart';
import '../../../core/engine/theme/theme_api.dart';
import '../../../core/layout/grid/grid_extensions.dart';

/// 🖼️ 通用海报卡片组件 (Generic Poster Card Component)
class PosterCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? badgeText;
  final String? cornerText;
  final bool isFocused;
  final VoidCallback onTap;
  final IconData placeholderIcon;

  const PosterCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.badgeText,
    this.cornerText,
    required this.isFocused,
    required this.onTap,
    this.placeholderIcon = Icons.movie_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final layer = isFocused ? ThemeLayer.above : ThemeLayer.base;

    return ThemeIdentity(
      role: ThemeRole.card,
      layer: layer,
      child: Builder(
        builder: (context) {
          final material = context.useTheme();
          final colors = material.colors;
          final chrome = material.visual;

          final List<BoxShadow>? shadows = isFocused
              ? chrome.outerShadows
                    .map(
                      (e) => BoxShadow(
                        color: e.color,
                        offset: e.offset,
                        blurRadius: e.blurRadius,
                      ),
                    )
                    .toList()
              : null;

          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: material.shape.radius,
                boxShadow: shadows,
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: material.shape.radius,
                border: Border.all(
                  color: isFocused ? colors.accent : colors.border,
                  width: isFocused ? 2.0 : 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedScale(
                scale: isFocused ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 海报图区域 ───────────────────────────────────────────────
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          PosterImage(
                            imageUrl: imageUrl,
                            placeholder: colors.backgroundFocused,
                            placeholderIcon: placeholderIcon,
                          ),
                          if (badgeText != null && badgeText!.isNotEmpty)
                            Positioned(
                              top: context.units(0.8),
                              right: context.units(0.8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.units(0.6),
                                  vertical: context.units(0.3),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  badgeText!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: context.units(0.9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // ── 元数据文字排版区 ─────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.units(1.1),
                        vertical: context.units(0.9),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: context.units(1.2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: context.units(0.4)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  subtitle ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: context.units(1.0),
                                  ),
                                ),
                              ),
                              if (cornerText != null && cornerText!.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.units(0.4),
                                    vertical: context.units(0.1),
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    cornerText!,
                                    style: TextStyle(
                                      color: colors.accent,
                                      fontSize: context.units(0.9),
                                      fontWeight: FontWeight.bold,
                                    ),
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
            ),
          );
        },
      ),
    );
  }
}

/// 海报图片组件：优先 Image.network，无链接时显示占位色块
class PosterImage extends StatelessWidget {
  final String? imageUrl;
  final Color placeholder;
  final IconData placeholderIcon;

  const PosterImage({
    super.key, 
    this.imageUrl, 
    required this.placeholder,
    required this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return PlaceholderView(color: placeholder, icon: placeholderIcon);
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return PlaceholderView(color: placeholder, icon: placeholderIcon);
      },
      errorBuilder: (_, e, s) => PlaceholderView(color: placeholder, icon: placeholderIcon),
    );
  }
}

/// 无海报时的占位色块
class PlaceholderView extends StatelessWidget {
  final Color color;
  final IconData icon;

  const PlaceholderView({
    super.key, 
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Icon(
          icon,
          size: context.units(4.0),
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}
