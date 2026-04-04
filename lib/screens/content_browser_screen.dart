import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer_book_model.dart';
import '../providers/prayer_book_provider.dart';
import '../utils/app_colors.dart';
import 'chapter_screen.dart';

const List<Color> _sectionAccents = [
  Color(0xFF4A90C4),
  Color(0xFF2C6B9A),
  Color(0xFF3A7DBD),
  Color(0xFF5499C7),
  Color(0xFF1A5C8A),
  Color(0xFF6AAED6),
  Color(0xFF2980B9),
  Color(0xFF1F6FA3),
];

/// Full page browser with section grouping and go-to-page navigation.
class ContentBrowserScreen extends StatefulWidget {
  const ContentBrowserScreen({super.key});

  @override
  State<ContentBrowserScreen> createState() => _ContentBrowserScreenState();
}

class _ContentBrowserScreenState extends State<ContentBrowserScreen> {
  int? _selectedSectionId;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerBookProvider>();
    final book = provider.book;
    if (book == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final allPages = provider.allPages;
    final filtered = _selectedSectionId == null
        ? allPages
        : allPages.where((fp) => fp.section.id == _selectedSectionId).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amapaji Yose',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Amapaji ${provider.totalPages} mu bice ${book.sections.length}',
              style: GoogleFonts.lato(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.primary),
            tooltip: 'Jya ku paji',
            onPressed: () => _showGoToDialog(context, provider),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _SectionFilterRow(
            sections: book.sections,
            selectedId: _selectedSectionId,
            onSelect: (id) => setState(() => _selectedSectionId = id),
          ),
        ),
      ),
      body: _selectedSectionId == null
          ? _GroupedList(
              allPages: filtered,
              sections: book.sections,
              scrollController: _scrollController,
            )
          : _FlatList(pages: filtered),
    );
  }

  void _showGoToDialog(BuildContext context, PrayerBookProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Jya ku Paji',
          style: GoogleFonts.playfairDisplay(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '1 – ${provider.totalPages}',
            prefixIcon: const Icon(Icons.auto_stories_outlined,
                color: AppColors.primary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Reka',
                style: GoogleFonts.lato(color: AppColors.grey600)),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text.trim());
              Navigator.pop(ctx);
              if (page == null) return;
              final fp = provider.pageAtNumber(page);
              if (fp == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PageReadingScreen(flatPage: fp),
                ),
              );
            },
            child: Text(
              'Genda',
              style: GoogleFonts.lato(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section filter row ────────────────────────────────────────────────────────

class _SectionFilterRow extends StatelessWidget {
  final List<Section> sections;
  final int? selectedId;
  final void Function(int?) onSelect;

  const _SectionFilterRow({
    required this.sections,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'Byose',
            selected: selectedId == null,
            color: AppColors.primary,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...sections.asMap().entries.map((e) {
            final accent = _sectionAccents[e.key % _sectionAccents.length];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: e.value.title,
                selected: selectedId == e.value.id,
                color: accent,
                onTap: () =>
                    onSelect(selectedId == e.value.id ? null : e.value.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.divider),
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

// ── Grouped list (all sections) ───────────────────────────────────────────────

class _GroupedList extends StatelessWidget {
  final List<FlatPage> allPages;
  final List<Section> sections;
  final ScrollController scrollController;

  const _GroupedList({
    required this.allPages,
    required this.sections,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Group by section id
    final grouped = <int, List<FlatPage>>{};
    for (final fp in allPages) {
      grouped.putIfAbsent(fp.section.id, () => []).add(fp);
    }
    final sectionOrder = sections.map((s) => s.id).toList();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: sectionOrder.length,
      itemBuilder: (context, sIdx) {
        final sectionId = sectionOrder[sIdx];
        final fps = grouped[sectionId];
        if (fps == null || fps.isEmpty) return const SizedBox.shrink();

        final section = fps.first.section;
        final accent = _sectionAccents[sIdx % _sectionAccents.length];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      section.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${fps.length}',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...fps.map((fp) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BrowserTile(fp: fp, accent: accent),
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── Flat list (single section selected) ──────────────────────────────────────

class _FlatList extends StatelessWidget {
  final List<FlatPage> pages;

  const _FlatList({required this.pages});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: pages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final fp = pages[index];
        final accent =
            _sectionAccents[fp.sectionIndex % _sectionAccents.length];
        return _BrowserTile(fp: fp, accent: accent);
      },
    );
  }
}

// ── Browser tile ──────────────────────────────────────────────────────────────

String _flatPageTitle(FlatPage fp) {
  for (final p in fp.page.content) {
    if (p.isHeading) return p.text;
  }
  if (fp.subsection != null && fp.subsection!.title.isNotEmpty) {
    return fp.subsection!.title;
  }
  return fp.section.title;
}

class _BrowserTile extends StatelessWidget {
  final FlatPage fp;
  final Color accent;

  const _BrowserTile({required this.fp, required this.accent});

  @override
  Widget build(BuildContext context) {
    final title = _flatPageTitle(fp);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PageReadingScreen(flatPage: fp),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Page number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${fp.pageNum}',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paragarafe ${fp.page.nonEmptyCount}',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: accent.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
