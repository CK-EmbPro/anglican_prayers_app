class PrayerBookMetadata {
  final String title;
  final String fullTitle;
  final String subtitle;
  final String language;
  final String church;
  final int totalSections;
  final int totalChapters;
  final int totalVerses;

  const PrayerBookMetadata({
    required this.title,
    required this.fullTitle,
    required this.subtitle,
    required this.language,
    required this.church,
    required this.totalSections,
    required this.totalChapters,
    required this.totalVerses,
  });

  factory PrayerBookMetadata.fromJson(Map<String, dynamic> json) {
    return PrayerBookMetadata(
      title: json['title'] ?? '',
      fullTitle: json['fullTitle'] ?? '',
      subtitle: json['subtitle'] ?? '',
      language: json['language'] ?? '',
      church: json['church'] ?? '',
      totalSections: json['totalSections'] ?? 0,
      totalChapters: json['totalChapters'] ?? 0,
      totalVerses: json['totalVerses'] ?? 0,
    );
  }
}

class Verse {
  final int id;
  final String text;
  final String type;
  final String speaker;

  const Verse({
    required this.id,
    required this.text,
    required this.type,
    required this.speaker,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      type: json['type'] ?? 'prayer',
      speaker: json['speaker'] ?? 'all',
    );
  }

  bool get isEmpty => text.trim().isEmpty;
  bool get isHeading => type == 'heading';
  bool get isRubric => type == 'rubric' || type == 'instruction';
  bool get isResponse => type == 'response';
  bool get isCollect => type == 'collect';
  bool get isScripture => type == 'scripture';
  bool get isCreed => type == 'creed';
  bool get isCanticle => type == 'canticle';

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'type': type,
        'speaker': speaker,
      };
}

class Chapter {
  final int id;
  final String slug;
  final String title;
  final int order;
  final List<Verse> verses;
  final String? subtitle;

  const Chapter({
    required this.id,
    required this.slug,
    required this.title,
    required this.order,
    required this.verses,
    this.subtitle,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final verseList = (json['verses'] as List<dynamic>? ?? [])
        .map((v) => Verse.fromJson(v as Map<String, dynamic>))
        .toList();
    return Chapter(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      order: json['order'] ?? 0,
      verses: verseList,
      subtitle: json['subtitle'],
    );
  }

  int get nonEmptyVerseCount => verses.where((v) => !v.isEmpty).length;
}

class Section {
  final int id;
  final String slug;
  final String title;
  final String englishTitle;
  final String? description;
  final int order;
  final List<Chapter> chapters;

  const Section({
    required this.id,
    required this.slug,
    required this.title,
    required this.englishTitle,
    this.description,
    required this.order,
    required this.chapters,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    final chapterList = (json['chapters'] as List<dynamic>? ?? [])
        .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
        .toList();
    return Section(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      englishTitle: json['englishTitle'] ?? '',
      description: json['description'],
      order: json['order'] ?? 0,
      chapters: chapterList,
    );
  }

  int get totalVerses =>
      chapters.fold(0, (sum, c) => sum + c.verses.length);

  int get totalNonEmptyVerses =>
      chapters.fold(0, (sum, c) => sum + c.nonEmptyVerseCount);
}

class PrayerBook {
  final PrayerBookMetadata metadata;
  final List<Section> sections;

  const PrayerBook({required this.metadata, required this.sections});

  factory PrayerBook.fromJson(Map<String, dynamic> json) {
    final sectionList = (json['sections'] as List<dynamic>? ?? [])
        .map((s) => Section.fromJson(s as Map<String, dynamic>))
        .toList();
    return PrayerBook(
      metadata: PrayerBookMetadata.fromJson(
          json['metadata'] as Map<String, dynamic>),
      sections: sectionList,
    );
  }
}

// Flat structure for search results
class SearchResult {
  final int verseId;
  final String verseText;
  final String verseType;
  final int sectionId;
  final String sectionTitle;
  final int chapterId;
  final String chapterTitle;

  const SearchResult({
    required this.verseId,
    required this.verseText,
    required this.verseType,
    required this.sectionId,
    required this.sectionTitle,
    required this.chapterId,
    required this.chapterTitle,
  });
}

// Favourite item
class FavouriteItem {
  final int verseId;
  final String verseText;
  final String verseType;
  final int sectionId;
  final String sectionTitle;
  final String sectionSlug;
  final int chapterId;
  final String chapterTitle;
  final DateTime savedAt;

  const FavouriteItem({
    required this.verseId,
    required this.verseText,
    required this.verseType,
    required this.sectionId,
    required this.sectionTitle,
    required this.sectionSlug,
    required this.chapterId,
    required this.chapterTitle,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'verseId': verseId,
        'verseText': verseText,
        'verseType': verseType,
        'sectionId': sectionId,
        'sectionTitle': sectionTitle,
        'sectionSlug': sectionSlug,
        'chapterId': chapterId,
        'chapterTitle': chapterTitle,
        'savedAt': savedAt.toIso8601String(),
      };

  factory FavouriteItem.fromJson(Map<String, dynamic> json) {
    return FavouriteItem(
      verseId: json['verseId'] ?? 0,
      verseText: json['verseText'] ?? '',
      verseType: json['verseType'] ?? '',
      sectionId: json['sectionId'] ?? 0,
      sectionTitle: json['sectionTitle'] ?? '',
      sectionSlug: json['sectionSlug'] ?? '',
      chapterId: json['chapterId'] ?? 0,
      chapterTitle: json['chapterTitle'] ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
