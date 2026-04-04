import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer_book_model.dart';
import '../providers/prayer_book_provider.dart';
import '../utils/app_colors.dart';
import 'chapter_screen.dart';

const _typeFilters = [
  ('Ubwoko bwose', null),
  ('Gusenga', 'prayer'),
  ('Amasengesho', 'collect'),
  ('Igisubizo', 'response'),
  ('Ibyanditswe', 'scripture'),
  ("Imvugo y'Ukwizera", 'creed'),
  ('Indirimbo', 'canticle'),
  ('Amabwiriza', 'rubric'),
];

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
    final hasFilters =
        provider.typeFilter != null || provider.sectionFilter != null;
    final isActive = query.isNotEmpty || hasFilters;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Shakisha',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (val) => provider.search(val),
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Shakisha imisengero, amasengesho...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.primary, size: 20),
                    suffixIcon: _controller.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _controller.clear();
                              provider.clearSearch();
                              _focusNode.requestFocus();
                            },
                            child: const Icon(Icons.close,
                                color: AppColors.grey400, size: 18),
                          )
                        : null,
                  ),
                ),
              ),
              // Type filter chips
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: _typeFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final (label, value) = _typeFilters[i];
                    final selected = provider.typeFilter == value;
                    return _FilterChip(
                      label: label,
                      selected: selected,
                      onTap: () {
                        if (selected && value == null) return;
                        provider.setTypeFilter(selected ? null : value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      body: !isActive
          ? _EmptyState(provider: provider)
          : results.isEmpty
              ? _NoResults(query: query, hasFilter: hasFilters)
              : _ResultsList(
                  results: results,
                  query: query,
                  provider: provider,
                ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final PrayerBookProvider provider;

  const _EmptyState({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            "Shakisha mu Gitabo cy'Amasengesho",
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Shaka imisengero, amasengesho,\nibyanditswe byera n\'ibindi.',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppColors.textHint,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _SuggestionChip(label: 'Litani'),
              _SuggestionChip(label: 'Isabato'),
              _SuggestionChip(label: 'Kubatiza'),
              _SuggestionChip(label: 'Gushyingira'),
              _SuggestionChip(label: 'Ingingo'),
            ],
          ),
          const SizedBox(height: 32),
          _DiscoverCard(provider: provider),
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
      onTap: () => context.read<PrayerBookProvider>().search(label),
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

// ── Discover card ─────────────────────────────────────────────────────────────

class _DiscoverCard extends StatefulWidget {
  final PrayerBookProvider provider;

  const _DiscoverCard({required this.provider});

  @override
  State<_DiscoverCard> createState() => _DiscoverCardState();
}

class _DiscoverCardState extends State<_DiscoverCard> {
  SearchResult? _discovered;

  void _discover() {
    setState(() => _discovered = widget.provider.randomParagraph());
  }

  void _navigateTo(BuildContext context, SearchResult result) {
    final fp = widget.provider.pageAtNumber(result.pageNum);
    if (fp == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PageReadingScreen(flatPage: fp)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Vumbura',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _discover,
                child: Row(
                  children: [
                    const Icon(Icons.shuffle,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      "Paragarafe y'Inzirakarengane",
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_discovered != null)
            GestureDetector(
              onTap: () => _navigateTo(context, _discovered!),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _discovered!.breadcrumb,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _discovered!.paragraphText,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _TypeBadge(type: _discovered!.paragraphType),
                        const Spacer(),
                        Text(
                          'Paji ${_discovered!.pageNum}',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _discover,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 28,
                        color: AppColors.primary.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'Kanda kugira ngo uvumbure imigabane',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── No results ────────────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;
  final bool hasFilter;

  const _NoResults({required this.query, required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            query.isNotEmpty
                ? 'Nta bisubizo bya "$query"'
                : 'Nta bisubizo by\'ubwoko bwarenguye',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Gerageza guhindura ubwoko haruguru'
                : "Gerageza amagambo y'indi mvugo",
            style: GoogleFonts.lato(fontSize: 13, color: AppColors.textHint),
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
            'Ibisubizo: ${results.length}${results.length == 200 ? '+' : ''}',
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _ResultCard(
              result: results[index],
              query: query,
              provider: provider,
            ),
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

  String get _favKey => '${result.pageNum}_${result.paragraphIndex}';

  void _navigateTo(BuildContext context) {
    final fp = provider.pageAtNumber(result.pageNum);
    if (fp == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PageReadingScreen(flatPage: fp)),
    );
  }

  void _toggleFav() {
    provider.toggleFavourite(
      favKey: _favKey,
      pageNum: result.pageNum,
      paragraphIndex: result.paragraphIndex,
      paragraphText: result.paragraphText,
      paragraphType: result.paragraphType,
      sectionId: result.sectionId,
      sectionTitle: result.sectionTitle,
      subsectionId: result.subsectionId,
      subsectionTitle: result.subsectionTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFav = provider.isFavourite(_favKey);

    return GestureDetector(
      onTap: () => _navigateTo(context),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.breadcrumb,
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
                  onTap: _toggleFav,
                  child: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    size: 16,
                    color: isFav ? AppColors.favourite : AppColors.grey400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _HighlightedText(text: result.paragraphText, query: query),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeBadge(type: result.paragraphType),
                const Spacer(),
                Text(
                  'Paji ${result.pageNum}',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.lato(
            fontSize: 14, height: 1.6, color: AppColors.textPrimary),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.lato(
            fontSize: 14, height: 1.6, color: AppColors.textPrimary),
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
          fontSize: 14, height: 1.6, color: AppColors.textPrimary),
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
