import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer_book_model.dart';
import '../providers/prayer_book_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/verse_tile.dart';

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

class ChapterScreen extends StatefulWidget {
  final Section section;
  final Chapter chapter;
  final int sectionIndex;
  final int? globalPage;

  const ChapterScreen({
    super.key,
    required this.section,
    required this.chapter,
    required this.sectionIndex,
    this.globalPage,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFontControls = false;

  Color get _accent =>
      _sectionAccents[widget.sectionIndex % _sectionAccents.length];

  late List<Verse> _displayVerses;
  late int _resolvedGlobalPage;

  @override
  void initState() {
    super.initState();
    _displayVerses = widget.chapter.verses;
    _resolvedGlobalPage = widget.globalPage ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolve global page if not provided
    if (_resolvedGlobalPage == 0) {
      final provider = context.read<PrayerBookProvider>();
      _resolvedGlobalPage =
          provider.globalPageForChapter(widget.chapter.id) ?? 0;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _navigatePrev(BuildContext context, PrayerBookProvider provider) {
    if (_resolvedGlobalPage <= 1) return;
    final gc = provider.chapterAtPage(_resolvedGlobalPage - 1);
    if (gc == null) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChapterScreen(
          section: gc.section,
          chapter: gc.chapter,
          sectionIndex: gc.sectionIndex,
          globalPage: gc.globalPage,
        ),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
      ),
    );
  }

  void _navigateNext(BuildContext context, PrayerBookProvider provider) {
    if (_resolvedGlobalPage >= provider.totalPages) return;
    final gc = provider.chapterAtPage(_resolvedGlobalPage + 1);
    if (gc == null) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChapterScreen(
          section: gc.section,
          chapter: gc.chapter,
          sectionIndex: gc.sectionIndex,
          globalPage: gc.globalPage,
        ),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
      ),
    );
  }

  void _showGoToPageDialog(BuildContext context, PrayerBookProvider provider) {
    final controller = TextEditingController(
      text: _resolvedGlobalPage > 0 ? '$_resolvedGlobalPage' : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Go to prayer',
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
          decoration: InputDecoration(
            hintText: '1 – ${provider.totalPages}',
            prefixIcon: const Icon(Icons.auto_stories_outlined,
                color: AppColors.primary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.lato(color: AppColors.grey600)),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text.trim());
              Navigator.pop(ctx);
              if (page == null) return;
              final gc = provider.chapterAtPage(page);
              if (gc == null) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ChapterScreen(
                    section: gc.section,
                    chapter: gc.chapter,
                    sectionIndex: gc.sectionIndex,
                    globalPage: gc.globalPage,
                  ),
                ),
              );
            },
            child: Text(
              'Go',
              style: GoogleFonts.lato(
                color: _accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerBookProvider>();
    final totalPages = provider.totalPages;

    final hasPrev = _resolvedGlobalPage > 1;
    final hasNext = _resolvedGlobalPage < totalPages;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: AppColors.divider,
            iconTheme: const IconThemeData(color: AppColors.primary),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_back, color: _accent, size: 20),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chapter.title.isEmpty
                      ? widget.section.title
                      : widget.chapter.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      widget.section.title,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    if (_resolvedGlobalPage > 0) ...[
                      Text(
                        '  ·  ',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: AppColors.grey400,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _showGoToPageDialog(context, provider),
                        child: Text(
                          'Prayer $_resolvedGlobalPage of $totalPages',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: _accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            actions: [
              // Font size toggle
              IconButton(
                icon: Icon(
                  Icons.text_fields,
                  color: _showFontControls ? _accent : AppColors.grey600,
                ),
                tooltip: 'Font size',
                onPressed: () =>
                    setState(() => _showFontControls = !_showFontControls),
              ),
              const SizedBox(width: 4),
            ],
            bottom: _showFontControls
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(52),
                    child: _FontSizeBar(
                      provider: provider,
                      accent: _accent,
                    ),
                  )
                : PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(height: 1, color: AppColors.divider),
                  ),
          ),

          // ── Legend ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _LegendBar()),

          // ── Verses ──────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final verse = _displayVerses[index];
                  return VerseTile(
                    verse: verse,
                    sectionId: widget.section.id,
                    sectionTitle: widget.section.title,
                    sectionSlug: widget.section.slug,
                    chapterId: widget.chapter.id,
                    chapterTitle: widget.chapter.title,
                    globalPage: _resolvedGlobalPage,
                  );
                },
                childCount: _displayVerses.length,
              ),
            ),
          ),

          // ── Prev / Next navigation row ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _PageNavRow(
              hasPrev: hasPrev,
              hasNext: hasNext,
              accent: _accent,
              onPrev: () => _navigatePrev(context, provider),
              onNext: () => _navigateNext(context, provider),
              currentPage: _resolvedGlobalPage,
              totalPages: totalPages,
              onGoTo: () => _showGoToPageDialog(context, provider),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      floatingActionButton: _ScrollTopFab(
        scrollController: _scrollController,
        accent: _accent,
        onTap: _scrollToTop,
      ),
    );
  }
}

// ── Page nav row ──────────────────────────────────────────────────────────────

class _PageNavRow extends StatelessWidget {
  final bool hasPrev;
  final bool hasNext;
  final Color accent;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final int currentPage;
  final int totalPages;
  final VoidCallback onGoTo;

  const _PageNavRow({
    required this.hasPrev,
    required this.hasNext,
    required this.accent,
    required this.onPrev,
    required this.onNext,
    required this.currentPage,
    required this.totalPages,
    required this.onGoTo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _NavBtn(
            icon: Icons.chevron_left,
            label: 'Previous',
            enabled: hasPrev,
            accent: accent,
            onTap: onPrev,
          ),
          const Spacer(),
          GestureDetector(
            onTap: onGoTo,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentPage > 0 ? '$currentPage / $totalPages' : '—',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                Text(
                  'Tap to jump',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _NavBtn(
            icon: Icons.chevron_right,
            label: 'Next',
            enabled: hasNext,
            accent: accent,
            onTap: onNext,
            iconFirst: false,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;
  final bool iconFirst;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.accent,
    required this.onTap,
    this.iconFirst = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? accent : AppColors.grey400;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: iconFirst
            ? [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Text(label,
                    style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ]
            : [
                Text(label,
                    style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color)),
                const SizedBox(width: 4),
                Icon(icon, size: 18, color: color),
              ],
      ),
    );
  }
}

// ── Font size control bar ─────────────────────────────────────────────────────

class _FontSizeBar extends StatelessWidget {
  final PrayerBookProvider provider;
  final Color accent;

  const _FontSizeBar({required this.provider, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Text(
            'Text size',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          _FontButton(
            icon: Icons.remove,
            onTap: provider.decreaseFontSize,
            accent: accent,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '${provider.fontSize.toInt()}',
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          _FontButton(
            icon: Icons.add,
            onTap: provider.increaseFontSize,
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _FontButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  const _FontButton({
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 18, color: accent),
      ),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _LegendBar extends StatefulWidget {
  @override
  State<_LegendBar> createState() => _LegendBarState();
}

class _LegendBarState extends State<_LegendBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: AppColors.grey100,
          child: _expanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Reading guide',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.keyboard_arrow_up,
                            size: 16, color: AppColors.grey600),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: const [
                        _LegendItem(
                          color: AppColors.rubricColor,
                          label: 'Instruction',
                          italic: true,
                        ),
                        _LegendItem(
                          color: AppColors.primary,
                          label: 'Collect',
                          bordered: true,
                        ),
                        _LegendItem(
                          color: AppColors.scriptureColor,
                          label: 'Scripture',
                          bordered: true,
                        ),
                        _LegendItem(
                          color: AppColors.primaryLight,
                          label: 'Response',
                          bordered: true,
                        ),
                        _LegendItem(
                          color: AppColors.headingColor,
                          label: 'Heading',
                          bold: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'M. = Minister   C. = Congregation   All = Together',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Text(
                      'Reading guide',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.keyboard_arrow_down,
                        size: 16, color: AppColors.grey600),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool italic;
  final bool bold;
  final bool bordered;

  const _LegendItem({
    required this.color,
    required this.label,
    this.italic = false,
    this.bold = false,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: bordered ? color.withValues(alpha: 0.15) : color,
            borderRadius: BorderRadius.circular(2),
            border: bordered
                ? Border(left: BorderSide(color: color, width: 2))
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 11,
            color: color,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Scroll-to-top FAB ─────────────────────────────────────────────────────────

class _ScrollTopFab extends StatefulWidget {
  final ScrollController scrollController;
  final Color accent;
  final VoidCallback onTap;

  const _ScrollTopFab({
    required this.scrollController,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_ScrollTopFab> createState() => _ScrollTopFabState();
}

class _ScrollTopFabState extends State<_ScrollTopFab> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = widget.scrollController.offset > 400;
    if (shouldShow != _visible) {
      setState(() => _visible = shouldShow);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.small(
        onPressed: widget.onTap,
        backgroundColor: widget.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.keyboard_arrow_up, size: 22),
      ),
    );
  }
}
