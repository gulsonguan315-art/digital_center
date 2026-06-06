import 'package:flutter/material.dart';
import '../../../../core/engine/theme/theme_api.dart';
import '../../../../core/layout/grid/grid.dart';
import '../media_service.dart';
import 'core/media_detail_controller.dart';
import 'views_components/person_portrait_card.dart';

class MovieDetailView extends StatelessWidget {
  final MediaDetailController controller;

  const MovieDetailView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final material = context.useTheme();
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));

    final people = controller.processedPeople;

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
          height: grid.units(32), // Height for portrait cards + text
          child: ListView.separated(
            padding: EdgeInsets.only(left: grid.pageInset + context.units(8.0), right: grid.units(6)),
            scrollDirection: Axis.horizontal,
            cacheExtent: 1000.0,
            itemCount: people.length,
            separatorBuilder: (context, index) => SizedBox(width: grid.units(2)),
            itemBuilder: (context, index) {
              final person = people[index];
              final tag = person['PrimaryImageTag'] as String?;
              final itemId = person['Id'] as String?;
              
              String imageUrl = '';
              if (itemId != null && tag != null) {
                imageUrl = MediaService.instance.posterUrl(itemId, tag);
              }

              return PersonPortraitCard(
                person: person,
                imageUrl: imageUrl,
              );
            },
          ),
        ),
      ],
    );
  }
}
