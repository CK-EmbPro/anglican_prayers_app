import 'dart:convert';
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

  // Favourites
  List<FavouriteItem> _favourites = [];

  // Reading state
  int _currentSectionIndex = 0;
  int _currentChapterIndex = 0;

  // Font size
  double _fontSize = 16.0;

  PrayerBook? get book => _book;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<SearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  List<FavouriteItem> get favourites => _favourites;
  int get currentSectionIndex => _currentSectionIndex;
  int get currentChapterIndex => _currentChapterIndex;
  double get fontSize => _fontSize;

  Future<void> loadBook() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final jsonString =
          await rootBundle.loadString('assets/data/prayer_book.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      _book = PrayerBook.fromJson(jsonData);

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

  // ── Search ──────────────────────────────────────────────────────────────────

  void search(String query) {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final results = <SearchResult>[];
    final q = _searchQuery.toLowerCase();

    for (final section in _book?.sections ?? []) {
      for (final chapter in section.chapters) {
        for (final verse in chapter.verses) {
          if (verse.text.toLowerCase().contains(q)) {
            results.add(SearchResult(
              verseId: verse.id,
              verseText: verse.text,
              verseType: verse.type,
              sectionId: section.id,
              sectionTitle: section.title,
              chapterId: chapter.id,
              chapterTitle: chapter.title,
            ));
            if (results.length >= 200) break;
          }
        }
        if (results.length >= 200) break;
      }
      if (results.length >= 200) break;
    }

    _searchResults = results;
    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void setCurrentSection(int index) {
    _currentSectionIndex = index;
    _currentChapterIndex = 0;
    notifyListeners();
  }

  void setCurrentChapter(int index) {
    _currentChapterIndex = index;
    notifyListeners();
  }

  // ── Favourites ───────────────────────────────────────────────────────────────

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
    await prefs.setStringList('favourites', list);
  }

  Future<void> _loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favourites') ?? [];
    _favourites = list.map((s) {
      final map = json.decode(s) as Map<String, dynamic>;
      return FavouriteItem.fromJson(map);
    }).toList();
  }

  // ── Font Size ────────────────────────────────────────────────────────────────

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
