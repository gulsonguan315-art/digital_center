import 'package:flutter/material.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../../core/layout/grid/grid.dart';
import '../media_service.dart';
import '../../../../core/control/superfocus/focus_api.dart';

class MovieDetailView extends StatelessWidget {
  final Map<String, dynamic> details;

  const MovieDetailView({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));

    final allPeople = (details['People'] as List<dynamic>?) ?? [];
    
    final coreStaff = <Map<String, dynamic>>[];
    final actors = <Map<String, dynamic>>[];

    for (final p in allPeople) {
      final person = p as Map<String, dynamic>;
      final type = person['Type'] as String? ?? '';
      final hasImage = person['PrimaryImageTag'] != null;
      
      // 为了保持界面美观，仅显示有头像的人员
      if (!hasImage) continue;

      if (type == 'Director' || type == 'Writer') {
        // 去重：同一个人可能既是导演又是编剧
        if (!coreStaff.any((e) => e['Id'] == person['Id'])) {
          coreStaff.add(person);
        }
      } else if (type == 'Actor') {
        if (!actors.any((e) => e['Id'] == person['Id'])) {
          actors.add(person);
        }
      }
    }

    // 2. 拼接并限制数量 (优先导演/编剧，后面用演员补齐)
    final people = [...coreStaff, ...actors].take(15).toList();

    if (people.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: grid.pageInset + context.units(8.0), right: grid.units(6)),
          child: Text(
            '演职人员',
            style: TextStyle(
              fontSize: grid.units(2.4),
              fontWeight: FontWeight.bold,
              color: material.colors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: grid.units(2)),
        SizedBox(
          height: grid.units(32), // Height for portrait cards + text (increased to prevent overflow)
          child: ListView.separated(
            padding: EdgeInsets.only(left: grid.pageInset + context.units(8.0), right: grid.units(6)),
            scrollDirection: Axis.horizontal,
            cacheExtent: 1000.0,
            itemCount: people.length,
            separatorBuilder: (context, index) => SizedBox(width: grid.units(2)),
            itemBuilder: (context, index) {
              final person = people[index] as Map<String, dynamic>;
              final name = person['Name'] as String? ?? '';
              final role = person['Role'] as String? ?? '';
              final type = person['Type'] as String? ?? '';
              final tag = person['PrimaryImageTag'] as String?;
              final itemId = person['Id'] as String?;
              
              String imageUrl = '';
              if (itemId != null && tag != null) {
                // People images usually use the Item endpoint
                imageUrl = MediaService.instance.posterUrl(itemId, tag);
              }

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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(dynamic material) {
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
