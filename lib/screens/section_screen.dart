import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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

class SectionScreen extends StatelessWidget {
  final Section section;
  final int sectionIndex;

  const SectionScreen({
    super.key,
    required this.section,
    required this.sectionIndex,
  });

  Color get _accent => _sectionAccents[sectionIndex % _sectionAccents.length];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
              title: Text(
                section.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_accent, _accent.withValues(alpha: 0.75)],
                  ),
                ),
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Stats row ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _StatChip(
                    label: section.hasSubsections
                        ? 'Amapaji ${section.subsections!.length}'
                        : 'Amapaji ${section.pageCount}',
                    icon: Icons.auto_stories_outlined,
                    accent: _accent,
                  ),
                  _StatChip(
                    label: 'Paragarafe ${section.totalParagraphs}',
                    icon: Icons.format_quote,
                    accent: _accent,
                  ),
                  _StatChip(
                    label: 'Amapaji ${section.startPage} kugeza ${section.endPage}',
                    icon: Icons.bookmark_border,
                    accent: _accent,
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),

          // ── Content ─────────────────────────────────────────────────────────
          if (section.hasSubsections)
            _SubsectionList(
              section: section,
              sectionIndex: sectionIndex,
              accent: _accent,
            )
          else
            _PageList(
              section: section,
              sectionIndex: sectionIndex,
              accent: _accent,
            ),
        ],
      ),
    );
  }
}

// ── Subsection list (for sections 6-8) ───────────────────────────────────────

class _SubsectionList extends StatelessWidget {
  final Section section;
  final int sectionIndex;
  final Color accent;

  const _SubsectionList({
    required this.section,
    required this.sectionIndex,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final subsections = section.subsections!;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      sliver: AnimationLimiter(
        child: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final sub = subsections[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 24,
                  child: FadeInAnimation(
                    child: _SubsectionTile(
                      subsection: sub,
                      index: index,
                      accent: accent,
                      onTap: () {
                        final provider =
                            context.read<PrayerBookProvider>();
                        // Open first page of this subsection
                        final fp = provider.pageAtNumber(sub.startPage);
                        if (fp == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PageReadingScreen(flatPage: fp),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            childCount: subsections.length,
          ),
        ),
      ),
    );
  }
}

class _SubsectionTile extends StatelessWidget {
  final Subsection subsection;
  final int index;
  final Color accent;
  final VoidCallback onTap;

  const _SubsectionTile({
    required this.subsection,
    required this.index,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subsection.title,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Paragarafe ${subsection.totalParagraphs}',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                        Text(
                          '·  Amapaji ${subsection.startPage}–${subsection.endPage}',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: accent.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: accent.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page list (for sections 1-5) ─────────────────────────────────────────────

class _PageList extends StatelessWidget {
  final Section section;
  final int sectionIndex;
  final Color accent;

  const _PageList({
    required this.section,
    required this.sectionIndex,
    required this.accent,
  });

  String _pageTitle(PageContent page) {
    for (final p in page.content) {
      if (p.isHeading) return p.text;
    }
    // Fall back to first non-empty, non-rubric paragraph text (truncated)
    for (final p in page.content) {
      if (!p.isEmpty && !p.isRubric) return p.text;
    }
    return 'Page ${page.page}';
  }

  @override
  Widget build(BuildContext context) {
    final pages = section.pages ?? [];
    if (pages.length == 1) {
      return SliverToBoxAdapter(
        child: _SinglePageBanner(
          section: section,
          sectionIndex: sectionIndex,
          page: pages.first,
          accent: accent,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      sliver: AnimationLimiter(
        child: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final page = pages[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 24,
                  child: FadeInAnimation(
                    child: _PageListTile(
                      page: page,
                      index: index,
                      accent: accent,
                      title: _pageTitle(page),
                      onTap: () {
                        final provider =
                            context.read<PrayerBookProvider>();
                        final fp = provider.pageAtNumber(page.page);
                        if (fp == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PageReadingScreen(flatPage: fp),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            childCount: pages.length,
          ),
        ),
      ),
    );
  }
}

class _SinglePageBanner extends StatelessWidget {
  final Section section;
  final int sectionIndex;
  final PageContent page;
  final Color accent;

  const _SinglePageBanner({
    required this.section,
    required this.sectionIndex,
    required this.page,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          final provider = context.read<PrayerBookProvider>();
          final fp = provider.pageAtNumber(page.page);
          if (fp == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PageReadingScreen(flatPage: fp),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_stories_outlined, color: accent, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soma iki gice',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Paragarafe ${page.nonEmptyCount}',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageListTile extends StatelessWidget {
  final PageContent page;
  final int index;
  final Color accent;
  final String title;
  final VoidCallback onTap;

  const _PageListTile({
    required this.page,
    required this.index,
    required this.accent,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${page.page}',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paragarafe ${page.nonEmptyCount}',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: accent.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _StatChip({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
