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
    final provider = context.read<PrayerBookProvider>();
    final hasManyChapters = section.chapters.length > 1;

    // Pre-compute global pages for this section's chapters
    final chapterPages = <int, int>{};
    for (final gc in provider.allChapters) {
      if (gc.section.id == section.id) {
        chapterPages[gc.chapter.id] = gc.globalPage;
      }
    }

    final firstPage = chapterPages.values.isEmpty
        ? 0
        : chapterPages.values.reduce((a, b) => a < b ? a : b);
    final lastPage = chapterPages.values.isEmpty
        ? 0
        : chapterPages.values.reduce((a, b) => a > b ? a : b);

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
                    colors: [
                      _accent,
                      _accent.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(72, 60, 20, 0),
                  child: Text(
                    section.englishTitle,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
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
                    label: '${section.chapters.length} prayers',
                    icon: Icons.layers_outlined,
                    accent: _accent,
                  ),
                  _StatChip(
                    label: '${section.totalNonEmptyVerses} verses',
                    icon: Icons.format_quote,
                    accent: _accent,
                  ),
                  if (firstPage > 0)
                    _StatChip(
                      label: firstPage == lastPage
                          ? 'Prayer $firstPage'
                          : 'Prayers $firstPage–$lastPage',
                      icon: Icons.auto_stories_outlined,
                      accent: _accent,
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),

          // ── If single chapter → jump straight to reading ────────────────────
          if (!hasManyChapters)
            SliverToBoxAdapter(
              child: _SingleChapterBanner(
                section: section,
                sectionIndex: sectionIndex,
                accent: _accent,
                globalPage: chapterPages[section.chapters.first.id] ?? 0,
              ),
            )
          else ...[
            // ── Chapter list header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'Prayers',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHint,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // ── Chapter list ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: AnimationLimiter(
                child: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chapter = section.chapters[index];
                      final gPage = chapterPages[chapter.id] ?? 0;
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          verticalOffset: 24,
                          child: FadeInAnimation(
                            child: _ChapterListTile(
                              chapter: chapter,
                              index: index,
                              accent: _accent,
                              globalPage: gPage,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChapterScreen(
                                    section: section,
                                    chapter: chapter,
                                    sectionIndex: sectionIndex,
                                    globalPage: gPage,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: section.chapters.length,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Single-chapter banner (tap to read) ──────────────────────────────────────

class _SingleChapterBanner extends StatelessWidget {
  final Section section;
  final int sectionIndex;
  final Color accent;
  final int globalPage;

  const _SingleChapterBanner({
    required this.section,
    required this.sectionIndex,
    required this.accent,
    required this.globalPage,
  });

  @override
  Widget build(BuildContext context) {
    final chapter = section.chapters.first;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChapterScreen(
              section: section,
              chapter: chapter,
              sectionIndex: sectionIndex,
              globalPage: globalPage,
            ),
          ),
        ),
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
                      'Read this section',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${chapter.nonEmptyVerseCount} verses',
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

// ── Chapter list tile ─────────────────────────────────────────────────────────

class _ChapterListTile extends StatelessWidget {
  final Chapter chapter;
  final int index;
  final Color accent;
  final int globalPage;
  final VoidCallback onTap;

  const _ChapterListTile({
    required this.chapter,
    required this.index,
    required this.accent,
    required this.globalPage,
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
                      chapter.title.isEmpty
                          ? 'Prayer ${index + 1}'
                          : chapter.title,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chapter.subtitle != null &&
                        chapter.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        chapter.subtitle!,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${chapter.nonEmptyVerseCount} verses',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                        if (globalPage > 0) ...[
                          Text(
                            '  ·  Prayer $globalPage',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: accent.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
