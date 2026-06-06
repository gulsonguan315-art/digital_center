import 'package:flutter/material.dart';
import '../../../../core/layout/grid/grid.dart';
import '../media_service.dart';

import 'views_components/series_seasons_picker.dart';
import 'views_components/series_episodes_view.dart';

class SeriesDetailView extends StatefulWidget {
  final String seriesId;
  final Map<String, dynamic> details;

  const SeriesDetailView({
    super.key,
    required this.seriesId,
    required this.details,
  });

  @override
  State<SeriesDetailView> createState() => _SeriesDetailViewState();
}

class _SeriesDetailViewState extends State<SeriesDetailView> {
  List<Map<String, dynamic>> _seasons = [];
  List<Map<String, dynamic>> _episodes = [];
  String? _selectedSeasonId;
  bool _isLoadingSeasons = true;
  bool _isLoadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    final seasons = await MediaService.instance.fetchSeasons(widget.seriesId);
    if (mounted) {
      setState(() {
        _seasons = seasons;
        _isLoadingSeasons = false;
        if (_seasons.isNotEmpty) {
          _selectedSeasonId = _seasons.first['Id'] as String?;
          if (_selectedSeasonId != null) {
            _loadEpisodes(_selectedSeasonId!);
          }
        }
      });
    }
  }

  Future<void> _loadEpisodes(String seasonId) async {
    setState(() {
      _isLoadingEpisodes = true;
      _episodes = [];
    });
    final episodes = await MediaService.instance.fetchEpisodes(widget.seriesId, seasonId);
    if (mounted && _selectedSeasonId == seasonId) {
      setState(() {
        _episodes = episodes;
        _isLoadingEpisodes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grid = GridContext.fromViewport(MediaQuery.sizeOf(context));

    if (_isLoadingSeasons) {
      return SizedBox(
        height: grid.units(20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seasons Picker
          SeriesSeasonsPicker(
            seasons: _seasons,
            selectedSeasonId: _selectedSeasonId,
            onSeasonSelected: (id) {
              setState(() {
                _selectedSeasonId = id;
              });
              _loadEpisodes(id);
            },
          ),

          SizedBox(height: grid.units(3)),

          // Episodes List
          SeriesEpisodesView(
            episodes: _episodes,
            isLoading: _isLoadingEpisodes,
          ),
        ],
      ),
    );
  }
}
