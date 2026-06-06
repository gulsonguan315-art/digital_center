import 'package:flutter/material.dart';
import '../../../../../core/engine/theme/theme_api.dart';
import '../../../../../core/layout/grid/grid.dart';
import '../../../../../core/control/superfocus/focus_api.dart';

class PersonPortraitCard extends StatelessWidget {
  final Map<String, dynamic> person;
  final String imageUrl;

  const PersonPortraitCard({
    super.key,
    required this.person,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));

    final name = person['Name'] as String? ?? '';
    final role = person['Role'] as String? ?? '';
    final type = person['Type'] as String? ?? '';
    final itemId = person['Id'] as String?;

    return FocusIdentity(
      id: 'person_$itemId',
      alignment: FocusAlignment.center, // Auto-scroll scrollview when focused
      focusGeometry: RoundedRectFocusGeometry(
        borderRadius: material.shape.radius,
      ),
      builder: (context, hasFocus) {
        return SizedBox(
          width: grid.units(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar (Rounded Rectangle)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: grid.units(14),
                height: grid.units(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(grid.units(1)),
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
                  borderRadius: BorderRadius.circular(grid.units(1) - 3),
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
              // 身份标识 (优先显示导演/编剧)
              if (type.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: grid.units(0.5)),
                  child: Text(
                    _translateType(type),
                    style: TextStyle(
                      fontSize: grid.units(1.2),
                      color: material.colors.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              // Name
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: grid.units(1.6),
                  fontWeight: FontWeight.w600,
                  color: material.colors.textPrimary,
                ),
              ),
              // Role
              if (role.isNotEmpty)
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: grid.units(1.4),
                    color: material.colors.textSecondary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(ResolvedThemeMaterial material) {
    return Container(
      color: material.colors.foreground,
      child: Center(
        child: Icon(
          Icons.person,
          color: material.colors.textSecondary,
          size: 40,
        ),
      ),
    );
  }

  String _translateType(String type) {
    switch (type) {
      case 'Director':
        return '导演';
      case 'Writer':
        return '编剧';
      case 'Actor':
        return '演员';
      case 'Producer':
        return '制片人';
      default:
        return type;
    }
  }
}
