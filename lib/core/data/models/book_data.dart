class BookLibrary {
  final String id;
  final String name;
  final String icon;

  BookLibrary({required this.id, required this.name, required this.icon});

  factory BookLibrary.fromJson(Map<String, dynamic> json) {
    return BookLibrary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }
}

class BookItem {
  final String id;
  final String title;
  final String author;
  final String coverPath;
  final bool isSeries;
  final int numBooks;
  final List<String> libraryItemIds;

  BookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.coverPath,
    required this.isSeries,
    this.numBooks = 1,
    this.libraryItemIds = const [],
  });

  factory BookItem.fromJson(Map<String, dynamic> json) {
    final media = json['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final collapsedSeries = json['collapsedSeries'] as Map<String, dynamic>?;

    final isSeries = collapsedSeries != null;
    final numBooks = isSeries ? (collapsedSeries['numBooks'] as int? ?? 1) : 1;
    
    List<String> ids = [];
    if (isSeries && collapsedSeries['libraryItemIds'] is List) {
      ids = List<String>.from(collapsedSeries['libraryItemIds'] as List);
    }

    String authorName = metadata['authorName'] as String? ?? '';
    if (authorName.isEmpty && metadata['authors'] is List) {
      final authorsList = metadata['authors'] as List;
      authorName = authorsList
          .map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');
    }

    return BookItem(
      id: json['id'] as String? ?? '',
      title: isSeries 
          ? (collapsedSeries['name'] as String? ?? metadata['title'] as String? ?? '')
          : (metadata['title'] as String? ?? ''),
      author: authorName,
      coverPath: media['coverPath'] as String? ?? '',
      isSeries: isSeries,
      numBooks: numBooks,
      libraryItemIds: ids,
    );
  }
}
