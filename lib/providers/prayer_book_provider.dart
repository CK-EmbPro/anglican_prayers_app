import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_book_model.dart';

class PrayerBookProvider extends ChangeNotifier {
  PrayerBook? _book;
  bool _isLoading = true;
  String? _error;

  // Search
  String _searchQuery = '';
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  // Search filters
  String? _typeFilter;      // e.g. 'collect', 'response', 'scripture'
  int? _sectionFilter;      // section.id filter

  // Favourites
  List<FavouriteItem> _favourites = [];

  // Reading state
  int _currentSectionIndex = 0;
  int _currentChapterIndex = 0;

  // Font size
  double _fontSize = 16.0;

  // Cached flat chapter list (built once after load)
  List<GlobalChapter> _allChapters = [];

  // ── Getters ──────────────────────────────────────────────────────────────────

  PrayerBook? get book => _book;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<SearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get typeFilter => _typeFilter;
  int? get sectionFilter => _sectionFilter;
  List<FavouriteItem> get favourites => _favourites;
  int get currentSectionIndex => _currentSectionIndex;
  int get currentChapterIndex => _currentChapterIndex;
  double get fontSize => _fontSize;
  List<GlobalChapter> get allChapters => _allChapters;
  int get totalPages => _allChapters.length;

  // ── Load ──────────────────────────────────────────────────────────────────────

  Future<void> loadBook() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final jsonString =
          await rootBundle.loadString('assets/data/prayer_book.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      _book = PrayerBook.fromJson(jsonData);
      _allChapters = _book!.allChaptersFlat;

      await _loadFavourites();
      await _loadPreferences();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load prayer book: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────────

  void search(String query) {
    _searchQuery = query.trim();
    _runSearch();
  }

  void setTypeFilter(String? type) {
    _typeFilter = type;
    _runSearch();
  }

  void setSectionFilter(int? sectionId) {
    _sectionFilter = sectionId;
    _runSearch();
  }

  void clearFilters() {
    _typeFilter = null;
    _sectionFilter = null;
    _runSearch();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _typeFilter = null;
    _sectionFilter = null;
    notifyListeners();
  }

  void _runSearch() {
    if (_searchQuery.isEmpty && _typeFilter == null && _sectionFilter == null) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final results = <SearchResult>[];
    final q = _searchQuery.toLowerCase();

    for (final gc in _allChapters) {
      // Apply section filter
      if (_sectionFilter != null && gc.section.id != _sectionFilter) continue;

      for (final verse in gc.chapter.verses) {
        if (verse.isEmpty) continue;

        // Apply type filter
        if (_typeFilter != null && verse.type != _typeFilter) continue;

        // Apply text filter (skip if query is empty — type/section filter alone is enough)
        if (q.isNotEmpty && !verse.text.toLowerCase().contains(q)) continue;

        results.add(SearchResult(
          verseId: verse.id,
          verseText: verse.text,
          verseType: verse.type,
          sectionId: gc.section.id,
          sectionTitle: gc.section.title,
          chapterId: gc.chapter.id,
          chapterTitle: gc.chapter.title,
          globalPage: gc.globalPage,
        ));
        if (results.length >= 200) break;
      }
      if (results.length >= 200) break;
    }

    _searchResults = results;
    _isSearching = false;
    notifyListeners();
  }

  // ── Random discovery ─────────────────────────────────────────────────────────

  /// Returns a random verse from the full book (non-empty, non-heading).
  SearchResult? randomVerse() {
    final pool = <SearchResult>[];
    for (final gc in _allChapters) {
      for (final verse in gc.chapter.verses) {
        if (verse.isEmpty || verse.isHeading || verse.isRubric) continue;
        pool.add(SearchResult(
          verseId: verse.id,
          verseText: verse.text,
          verseType: verse.type,
          sectionId: gc.section.id,
          sectionTitle: gc.section.title,
          chapterId: gc.chapter.id,
          chapterTitle: gc.chapter.title,
          globalPage: gc.globalPage,
        ));
      }
    }
    if (pool.isEmpty) return null;
    return pool[Random().nextInt(pool.length)];
  }

  // ── Page navigation ───────────────────────────────────────────────────────────

  /// Returns the GlobalChapter at a 1-based global page number.
  GlobalChapter? chapterAtPage(int page) => _book?.chapterAtPage(page);

  /// Returns the global page number for a given chapter id.
  int? globalPageForChapter(int chapterId) {
    for (final gc in _allChapters) {
      if (gc.chapter.id == chapterId) return gc.globalPage;
    }
    return null;
  }

  // ── Navigation state ──────────────────────────────────────────────────────────

  void setCurrentSection(int index) {
    _currentSectionIndex = index;
    _currentChapterIndex = 0;
    notifyListeners();
  }

  void setCurrentChapter(int index) {
    _currentChapterIndex = index;
    notifyListeners();
  }

  // ── Favourites ────────────────────────────────────────────────────────────────

  bool isFavourite(int verseId) {
    return _favourites.any((f) => f.verseId == verseId);
  }

  void toggleFavourite({
    required int verseId,
    required String verseText,
    required String verseType,
    required int sectionId,
    required String sectionTitle,
    required String sectionSlug,
    required int chapterId,
    required String chapterTitle,
    required int globalPage,
  }) {
    final existing = _favourites.indexWhere((f) => f.verseId == verseId);
    if (existing >= 0) {
      _favourites.removeAt(existing);
    } else {
      _favourites.insert(
        0,
        FavouriteItem(
          verseId: verseId,
          verseText: verseText,
          verseType: verseType,
          sectionId: sectionId,
          sectionTitle: sectionTitle,
          sectionSlug: sectionSlug,
          chapterId: chapterId,
          chapterTitle: chapterTitle,
          globalPage: globalPage,
          savedAt: DateTime.now(),
        ),
      );
    }
    _saveFavourites();
    notifyListeners();
  }

  void removeFavourite(int verseId) {
    _favourites.removeWhere((f) => f.verseId == verseId);
    _saveFavourites();
    notifyListeners();
  }

  Future<void> _saveFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _favourites.map((f) => json.encode(f.toJson())).toList();
    await prefs.setStringList('favourites_v2', list);
  }

  Future<void> _loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    // Try new key first, fall back to old key for migration
    final list = prefs.getStringList('favourites_v2') ??
        prefs.getStringList('favourites') ??
        [];
    _favourites = list.map((s) {
      try {
        final map = json.decode(s) as Map<String, dynamic>;
        return FavouriteItem.fromJson(map);
      } catch (_) {
        return null;
      }
    }).whereType<FavouriteItem>().toList();
  }

  // ── Font size ─────────────────────────────────────────────────────────────────

  void increaseFontSize() {
    if (_fontSize < 24) {
      _fontSize += 1;
      _savePreferences();
      notifyListeners();
    }
  }

  void decreaseFontSize() {
    if (_fontSize > 12) {
      _fontSize -= 1;
      _savePreferences();
      notifyListeners();
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
  }
}
