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
  String? _typeFilter;
  int? _sectionFilter;

  // Favourites
  List<FavouriteItem> _favourites = [];

  // Font size
  double _fontSize = 16.0;

  // Cached flat page list (built once after load)
  List<FlatPage> _allPages = [];

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
  double get fontSize => _fontSize;
  List<FlatPage> get allPages => _allPages;
  int get totalPages => _allPages.length;

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
      _allPages = _book!.allPages;

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

  // ── Page navigation ───────────────────────────────────────────────────────────

  /// Returns the FlatPage for a given 1-based PDF page number.
  FlatPage? pageAtNumber(int pageNum) {
    try {
      return _allPages.firstWhere((fp) => fp.pageNum == pageNum);
    } catch (_) {
      return null;
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

    for (final fp in _allPages) {
      if (_sectionFilter != null && fp.section.id != _sectionFilter) continue;

      for (int pi = 0; pi < fp.page.content.length; pi++) {
        final para = fp.page.content[pi];
        if (para.isEmpty) continue;
        if (_typeFilter != null && para.type != _typeFilter) continue;
        if (q.isNotEmpty && !para.text.toLowerCase().contains(q)) continue;

        results.add(SearchResult(
          pageNum: fp.pageNum,
          paragraphIndex: pi,
          paragraphText: para.text,
          paragraphType: para.type,
          sectionId: fp.section.id,
          sectionTitle: fp.section.title,
          subsectionId: fp.subsection?.id,
          subsectionTitle: fp.subsection?.title,
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

  SearchResult? randomParagraph() {
    final pool = <SearchResult>[];
    for (final fp in _allPages) {
      for (int pi = 0; pi < fp.page.content.length; pi++) {
        final para = fp.page.content[pi];
        if (para.isEmpty || para.isHeading || para.isRubric) continue;
        pool.add(SearchResult(
          pageNum: fp.pageNum,
          paragraphIndex: pi,
          paragraphText: para.text,
          paragraphType: para.type,
          sectionId: fp.section.id,
          sectionTitle: fp.section.title,
          subsectionId: fp.subsection?.id,
          subsectionTitle: fp.subsection?.title,
        ));
      }
    }
    if (pool.isEmpty) return null;
    return pool[Random().nextInt(pool.length)];
  }

  // ── Favourites ────────────────────────────────────────────────────────────────

  bool isFavourite(String favKey) {
    return _favourites.any((f) => f.favKey == favKey);
  }

  void toggleFavourite({
    required String favKey,
    required int pageNum,
    required int paragraphIndex,
    required String paragraphText,
    required String paragraphType,
    required int sectionId,
    required String sectionTitle,
    String? subsectionId,
    String? subsectionTitle,
  }) {
    final existing = _favourites.indexWhere((f) => f.favKey == favKey);
    if (existing >= 0) {
      _favourites.removeAt(existing);
    } else {
      _favourites.insert(
        0,
        FavouriteItem(
          favKey: favKey,
          pageNum: pageNum,
          paragraphIndex: paragraphIndex,
          paragraphText: paragraphText,
          paragraphType: paragraphType,
          sectionId: sectionId,
          sectionTitle: sectionTitle,
          subsectionId: subsectionId,
          subsectionTitle: subsectionTitle,
          savedAt: DateTime.now(),
        ),
      );
    }
    _saveFavourites();
    notifyListeners();
  }

  void removeFavourite(String favKey) {
    _favourites.removeWhere((f) => f.favKey == favKey);
    _saveFavourites();
    notifyListeners();
  }

  Future<void> _saveFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _favourites.map((f) => json.encode(f.toJson())).toList();
    await prefs.setStringList('favourites_v3', list);
  }

  Future<void> _loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    // v3 is the page-based key; earlier verse-based keys are incompatible
    final list = prefs.getStringList('favourites_v3') ?? [];
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
