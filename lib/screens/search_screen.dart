import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer_book_model.dart';
import '../providers/prayer_book_provider.dart';
import '../utils/app_colors.dart';
import 'chapter_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerBookProvider>();
    final results = provider.searchResults;
    final query = provider.searchQuery;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Search',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (val) => provider.search(val),
              style: GoogleFonts.lato(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search prayers, verses, articles...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primary,
                  size: 20,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _controller.clear();
                          provider.clearSearch();
                          _focusNode.requestFocus();
                        },
                        child: const Icon(
                          Icons.close,
                          color: AppColors.grey400,
                          size: 18,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: query.isEmpty
          ? _EmptyState()
          : results.isEmpty
              ? _NoResults(query: query)
              : _ResultsList(
                  results: results,
                  query: query,
                  provider: provider,
                ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Search the Prayer Book',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find prayers, collects, articles,\nscripture passages and more.',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppColors.textHint,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Quick filter chips
          Wrap(
            spacing: 8,
            children: const [
              _SuggestionChip(label: 'Litani'),
              _SuggestionChip(label: 'Isabato'),
              _SuggestionChip(label: 'Kubatiza'),
              _SuggestionChip(label: 'Gushyingira'),
              _SuggestionChip(label: 'Ingingo'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;

  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final provider = context.read<PrayerBookProvider>();
        provider.search(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── No results ────────────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;

  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Results list ──────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final String query;
  final PrayerBookProvider provider;

  const _ResultsList({
    required this.results,
    required this.query,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Text(
            '${results.length}${results.length == 200 ? '+' : ''} results',
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final result = results[index];
              return _ResultCard(
                result: result,
                query: query,
                provider: provider,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SearchResult result;
  final String query;
  final PrayerBookProvider provider;

  const _ResultCard({
    required this.result,
    required this.query,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isFav = provider.isFavourite(result.verseId);

    return GestureDetector(
      onTap: () => _navigateToChapter(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${result.sectionTitle}  /  ${result.chapterTitle}',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _toggleFav(context),
                  child: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    size: 16,
                    color: isFav ? AppColors.favourite : AppColors.grey400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Highlighted text
            _HighlightedText(text: result.verseText, query: query),
            const SizedBox(height: 8),
            // Type badge
            _TypeBadge(type: result.verseType),
          ],
        ),
      ),
    );
  }

  void _navigateToChapter(BuildContext context) {
    final book = provider.book;
    if (book == null) return;

    Section? section;
    Chapter? chapter;
    int sectionIndex = 0;

    for (int i = 0; i < book.sections.length; i++) {
      final s = book.sections[i];
      if (s.id == result.sectionId) {
        section = s;
        sectionIndex = i;
        for (final c in s.chapters) {
          if (c.id == result.chapterId) {
            chapter = c;
            break;
          }
        }
        break;
      }
    }

    if (section != null && chapter != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChapterScreen(
            section: section!,
            chapter: chapter!,
            sectionIndex: sectionIndex,
          ),
        ),
      );
    }
  }

  void _toggleFav(BuildContext context) {
    provider.toggleFavourite(
      verseId: result.verseId,
      verseText: result.verseText,
      verseType: result.verseType,
      sectionId: result.sectionId,
      sectionTitle: result.sectionTitle,
      sectionSlug: '',
      chapterId: result.chapterId,
      chapterTitle: result.chapterTitle,
    );
  }
}

// ── Highlighted text ──────────────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.lato(
          fontSize: 14,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
      );
    }

    final before = text.substring(0, index);
    final match = text.substring(index, index + query.length);
    final after = text.substring(index + query.length);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(
              backgroundColor: Color(0xFFD4ECFF),
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.lato(
        fontSize: 14,
        height: 1.6,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  Color get _color {
    switch (type) {
      case 'collect':
        return AppColors.primary;
      case 'scripture':
        return AppColors.scriptureColor;
      case 'response':
        return AppColors.primaryDark;
      case 'rubric':
      case 'instruction':
        return AppColors.rubricColor;
      case 'heading':
        return AppColors.headingColor;
      default:
        return AppColors.grey600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: GoogleFonts.lato(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
