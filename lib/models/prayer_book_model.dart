// ══════════════════════════════════════════════════════════════════════════════
// Data models for page-based prayer book JSON (structureVersion 2.0)
// Hierarchy: PrayerBook > Section > (Subsection >) PageContent > Paragraph
// ══════════════════════════════════════════════════════════════════════════════

// ── Paragraph (replaces Verse) ────────────────────────────────────────────────

class Paragraph {
  final String text;
  final String type;
  final String speaker;

  const Paragraph({
    required this.text,
    required this.type,
    required this.speaker,
  });

  factory Paragraph.fromJson(Map<String, dynamic> json) {
    return Paragraph(
      text: json['text'] ?? '',
      type: json['type'] ?? 'prayer',
      speaker: json['speaker'] ?? 'all',
    );
  }

  Map<String, dynamic> toJson() =>
      {'text': text, 'type': type, 'speaker': speaker};

  bool get isEmpty => text.trim().isEmpty;
  bool get isHeading => type == 'heading';
  bool get isRubric => type == 'rubric' || type == 'instruction';
  bool get isResponse => type == 'response';
  bool get isCollect => type == 'collect';
  bool get isScripture => type == 'scripture';
  bool get isCreed => type == 'creed';
  bool get isCanticle => type == 'canticle';
}

// ── PageContent ───────────────────────────────────────────────────────────────

class PageContent {
  final int page;
  final List<Paragraph> content;

  const PageContent({required this.page, required this.content});

  factory PageContent.fromJson(Map<String, dynamic> json) {
    final items = (json['content'] as List<dynamic>? ?? [])
        .map((p) => Paragraph.fromJson(p as Map<String, dynamic>))
        .toList();
    return PageContent(page: json['page'] ?? 0, content: items);
  }

  int get nonEmptyCount => content.where((p) => !p.isEmpty).length;
}

// ── Subsection ────────────────────────────────────────────────────────────────

class Subsection {
  final String id;
  final String slug;
  final String title;
  final String englishTitle;
  final int startPage;
  final int endPage;
  final List<PageContent> pages;

  const Subsection({
    required this.id,
    required this.slug,
    required this.title,
    required this.englishTitle,
    required this.startPage,
    required this.endPage,
    required this.pages,
  });

  factory Subsection.fromJson(Map<String, dynamic> json) {
    final pageList = (json['pages'] as List<dynamic>? ?? [])
        .map((p) => PageContent.fromJson(p as Map<String, dynamic>))
        .toList();
    return Subsection(
      id: json['id']?.toString() ?? '',
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      englishTitle: json['englishTitle'] ?? '',
      startPage: json['startPage'] ?? 0,
      endPage: json['endPage'] ?? 0,
      pages: pageList,
    );
  }

  int get totalParagraphs =>
      pages.fold(0, (sum, p) => sum + p.nonEmptyCount);
  int get pageCount => endPage - startPage + 1;
}

// ── Section ───────────────────────────────────────────────────────────────────

class Section {
  final int id;
  final String slug;
  final String title;
  final String englishTitle;
  final String description;
  final int startPage;
  final int endPage;
  // Exactly one of subsections/pages is non-null
  final List<Subsection>? subsections;
  final List<PageContent>? pages;

  const Section({
    required this.id,
    required this.slug,
    required this.title,
    required this.englishTitle,
    required this.description,
    required this.startPage,
    required this.endPage,
    this.subsections,
    this.pages,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    final subList = (json['subsections'] as List<dynamic>?)
        ?.map((s) => Subsection.fromJson(s as Map<String, dynamic>))
        .toList();
    final pageList = (json['pages'] as List<dynamic>?)
        ?.map((p) => PageContent.fromJson(p as Map<String, dynamic>))
        .toList();
    return Section(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      englishTitle: json['englishTitle'] ?? '',
      description: json['description'] ?? '',
      startPage: json['startPage'] ?? 0,
      endPage: json['endPage'] ?? 0,
      subsections: subList,
      pages: pageList,
    );
  }

  bool get hasSubsections => subsections != null && subsections!.isNotEmpty;
  int get pageCount => endPage - startPage + 1;

  int get totalParagraphs {
    if (hasSubsections) {
      return subsections!.fold(0, (sum, s) => sum + s.totalParagraphs);
    }
    return pages?.fold<int>(0, (sum, p) => sum + p.nonEmptyCount) ?? 0;
  }

  /// All pages in this section, regardless of subsection nesting.
  List<PageContent> get allPages {
    if (pages != null) return pages!;
    return subsections!.expand((s) => s.pages).toList();
  }
}

// ── Metadata ──────────────────────────────────────────────────────────────────

class PrayerBookMetadata {
  final String title;
  final String fullTitle;
  final String subtitle;
  final String language;
  final String church;
  final int totalSections;
  final int totalPages;
  final int totalParagraphs;
  final String structureVersion;
  final String generatedDate;

  const PrayerBookMetadata({
    required this.title,
    required this.fullTitle,
    required this.subtitle,
    required this.language,
    required this.church,
    required this.totalSections,
    required this.totalPages,
    required this.totalParagraphs,
    required this.structureVersion,
    required this.generatedDate,
  });

  factory PrayerBookMetadata.fromJson(Map<String, dynamic> json) {
    return PrayerBookMetadata(
      title: json['title'] ?? '',
      fullTitle: json['fullTitle'] ?? '',
      subtitle: json['subtitle'] ?? '',
      language: json['language'] ?? '',
      church: json['church'] ?? '',
      totalSections: json['totalSections'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalParagraphs: json['totalParagraphs'] ?? 0,
      structureVersion: json['structureVersion'] ?? '2.0-page-based',
      generatedDate: json['generatedDate'] ?? '',
    );
  }
}

// ── PrayerBook ────────────────────────────────────────────────────────────────

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

  /// Flat list of every page in the book, enriched with context.
  List<FlatPage> get allPages {
    final result = <FlatPage>[];
    for (int si = 0; si < sections.length; si++) {
      final section = sections[si];
      if (section.hasSubsections) {
        for (int ui = 0; ui < section.subsections!.length; ui++) {
          final sub = section.subsections![ui];
          for (final pg in sub.pages) {
            result.add(FlatPage(
              page: pg,
              section: section,
              sectionIndex: si,
              subsection: sub,
              subsectionIndex: ui,
            ));
          }
        }
      } else {
        for (final pg in section.pages ?? <PageContent>[]) {
          result.add(FlatPage(
            page: pg,
            section: section,
            sectionIndex: si,
            subsection: null,
            subsectionIndex: -1,
          ));
        }
      }
    }
    return result;
  }
}

// ── FlatPage ──────────────────────────────────────────────────────────────────

/// A page enriched with its section and optional subsection context.
class FlatPage {
  final PageContent page;
  final Section section;
  final int sectionIndex;
  final Subsection? subsection;
  final int subsectionIndex;

  const FlatPage({
    required this.page,
    required this.section,
    required this.sectionIndex,
    this.subsection,
    required this.subsectionIndex,
  });

  int get pageNum => page.page;

  /// Breadcrumb: "Section title  /  Subsection title" (if applicable)
  String get breadcrumb {
    if (subsection != null && subsection!.title.isNotEmpty) {
      return '${section.title}  /  ${subsection!.title}';
    }
    return section.title;
  }
}

// ── Search result ─────────────────────────────────────────────────────────────

class SearchResult {
  final int pageNum;
  final int paragraphIndex;
  final String paragraphText;
  final String paragraphType;
  final int sectionId;
  final String sectionTitle;
  final String? subsectionId;
  final String? subsectionTitle;

  const SearchResult({
    required this.pageNum,
    required this.paragraphIndex,
    required this.paragraphText,
    required this.paragraphType,
    required this.sectionId,
    required this.sectionTitle,
    this.subsectionId,
    this.subsectionTitle,
  });

  String get breadcrumb {
    if (subsectionTitle != null && subsectionTitle!.isNotEmpty) {
      return '$sectionTitle  /  $subsectionTitle';
    }
    return sectionTitle;
  }
}

// ── Favourite item ────────────────────────────────────────────────────────────

class FavouriteItem {
  /// Unique key: "${pageNum}_${paragraphIndex}"
  final String favKey;
  final int pageNum;
  final int paragraphIndex;
  final String paragraphText;
  final String paragraphType;
  final int sectionId;
  final String sectionTitle;
  final String? subsectionId;
  final String? subsectionTitle;
  final DateTime savedAt;

  const FavouriteItem({
    required this.favKey,
    required this.pageNum,
    required this.paragraphIndex,
    required this.paragraphText,
    required this.paragraphType,
    required this.sectionId,
    required this.sectionTitle,
    this.subsectionId,
    this.subsectionTitle,
    required this.savedAt,
  });

  String get breadcrumb {
    if (subsectionTitle != null && subsectionTitle!.isNotEmpty) {
      return '$sectionTitle  /  $subsectionTitle';
    }
    return sectionTitle;
  }

  Map<String, dynamic> toJson() => {
        'favKey': favKey,
        'pageNum': pageNum,
        'paragraphIndex': paragraphIndex,
        'paragraphText': paragraphText,
        'paragraphType': paragraphType,
        'sectionId': sectionId,
        'sectionTitle': sectionTitle,
        'subsectionId': subsectionId,
        'subsectionTitle': subsectionTitle,
        'savedAt': savedAt.toIso8601String(),
      };

  factory FavouriteItem.fromJson(Map<String, dynamic> json) {
    return FavouriteItem(
      favKey: json['favKey'] ?? '',
      pageNum: json['pageNum'] ?? 0,
      paragraphIndex: json['paragraphIndex'] ?? 0,
      paragraphText: json['paragraphText'] ?? '',
      paragraphType: json['paragraphType'] ?? '',
      sectionId: json['sectionId'] ?? 0,
      sectionTitle: json['sectionTitle'] ?? '',
      subsectionId: json['subsectionId'],
      subsectionTitle: json['subsectionTitle'],
      savedAt: DateTime.tryParse(json['savedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
