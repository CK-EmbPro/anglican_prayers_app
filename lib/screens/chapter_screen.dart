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

/// Reading screen — swipe left/right to navigate between PDF pages.
class PageReadingScreen extends StatefulWidget {
  final FlatPage flatPage;
  const PageReadingScreen({super.key, required this.flatPage});

  @override
  State<PageReadingScreen> createState() => _PageReadingScreenState();
}

class _PageReadingScreenState extends State<PageReadingScreen> {
  late PageController _pageController;
  late List<FlatPage> _allPages;
  late int _currentIndex;
  bool _showFontControls = false;

  @override
  void initState() {
    super.initState();
    _allPages = context.read<PrayerBookProvider>().allPages;
    _currentIndex = _allPages.indexWhere(
      (fp) => fp.pageNum == widget.flatPage.pageNum,
    );
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  FlatPage get _current => _allPages[_currentIndex];

  Color get _accent =>
      _sectionAccents[_current.sectionIndex % _sectionAccents.length];

  void _showGoToDialog(BuildContext context) {
    final ctrl = TextEditingController(text: '${_current.pageNum}');
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
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '1 – ${_allPages.length}',
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
              final page = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx);
              if (page == null) return;
              final idx =
                  _allPages.indexWhere((fp) => fp.pageNum == page);
              if (idx < 0) return;
              _pageController.animateToPage(
                idx,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            child: Text(
              'Genda',
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
    final fp = _current;
    final total = _allPages.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.divider,
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
              fp.section.title,
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
                if (fp.subsection != null &&
                    fp.subsection!.title.isNotEmpty) ...[
                  Flexible(
                    child: Text(
                      fp.subsection!.title,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('  ·  ',
                      style: GoogleFonts.lato(
                          fontSize: 11, color: AppColors.grey400)),
                ],
                Flexible(
                  child: GestureDetector(
                    onTap: () => _showGoToDialog(context),
                    child: Text(
                      'Paji ${fp.pageNum} muri $total',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: _accent,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.text_fields,
              color: _showFontControls ? _accent : AppColors.grey600,
            ),
            tooltip: "Ingano y'Inyandiko",
            onPressed: () =>
                setState(() => _showFontControls = !_showFontControls),
          ),
          const SizedBox(width: 4),
        ],
        bottom: _showFontControls
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: _FontSizeBar(provider: provider, accent: _accent),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: AppColors.divider),
              ),
      ),
      body: Column(
        children: [
          // Page swipe hint strip
          _SwipeHint(
            currentPage: fp.pageNum,
            totalPages: total,
            accent: _accent,
            onGoTo: () => _showGoToDialog(context),
          ),
          // Swipeable page content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: _allPages.length,
              itemBuilder: (context, i) => _SinglePageContent(
                flatPage: _allPages[i],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Swipe hint / page indicator ───────────────────────────────────────────────

class _SwipeHint extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color accent;
  final VoidCallback onGoTo;

  const _SwipeHint({
    required this.currentPage,
    required this.totalPages,
    required this.accent,
    required this.onGoTo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.swipe, size: 14, color: AppColors.grey400),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Sunika ujye ku paji ikurikira cyangwa ibanze',
              style: GoogleFonts.lato(
                fontSize: 11,
                color: AppColors.textHint,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onGoTo,
            child: Text(
              '$currentPage / $totalPages',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single page content (scrollable, kept alive for smooth swipe-back) ────────

class _SinglePageContent extends StatefulWidget {
  final FlatPage flatPage;
  const _SinglePageContent({required this.flatPage});

  @override
  State<_SinglePageContent> createState() => _SinglePageContentState();
}

class _SinglePageContentState extends State<_SinglePageContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Groups consecutive table_header / table_row paragraphs into a single
  /// List<Paragraph> item so they can be rendered as one table widget.
  static List<dynamic> _buildDisplayItems(List<Paragraph> content) {
    final items = <dynamic>[];
    List<Paragraph>? tableGroup;
    for (final para in content) {
      if (para.isTableHeader || para.isTableRow) {
        tableGroup ??= [];
        tableGroup.add(para);
      } else {
        if (tableGroup != null) {
          items.add(tableGroup);
          tableGroup = null;
        }
        items.add(para);
      }
    }
    if (tableGroup != null) items.add(tableGroup);
    return items;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final fp = widget.flatPage;
    final displayItems = _buildDisplayItems(fp.page.content);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        if (item is List) {
          return _ZaburiTable(paragraphs: item.cast<Paragraph>());
        }
        return ParagraphTile(paragraph: item as Paragraph);
      },
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
            "Ingano y'Inyandiko",
            style: GoogleFonts.lato(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          _FontButton(
              icon: Icons.remove,
              onTap: provider.decreaseFontSize,
              accent: accent),
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
              accent: accent),
        ],
      ),
    );
  }
}

class _FontButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  const _FontButton(
      {required this.icon, required this.onTap, required this.accent});

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

// ── Zaburi Za Dawidi table ─────────────────────────────────────────────────────

class _ZaburiTable extends StatelessWidget {
  final List<Paragraph> paragraphs;

  const _ZaburiTable({required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    final fontSize = context.watch<PrayerBookProvider>().fontSize;

    Paragraph? header;
    final rows = <Paragraph>[];
    for (final p in paragraphs) {
      if (p.isTableHeader) {
        header = p;
      } else if (p.isTableRow) {
        rows.add(p);
      }
    }
    if (header == null && rows.isEmpty) return const SizedBox.shrink();

    final headerCols = header != null
        ? header.text.split('|')
        : ['Umunsi', 'Izo mugitondo', 'Izo nimugoroba'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(2.4),
          2: FlexColumnWidth(2.4),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Header row
          TableRow(
            children: [
              for (final col in headerCols)
                _TableCell(
                  text: col,
                  isHeader: true,
                  fontSize: fontSize,
                ),
            ],
          ),
          // Data rows
          for (final row in rows) ...[
            TableRow(
              children: () {
                final cols = row.text.split('|');
                while (cols.length < 3) {
                  cols.add('');
                }
                return [
                  for (final col in cols)
                    _TableCell(
                      text: col,
                      isHeader: false,
                      fontSize: fontSize,
                    ),
                ];
              }(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final double fontSize;

  const _TableCell({
    required this.text,
    required this.isHeader,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.lato(
          fontSize: isHeader ? fontSize - 1 : fontSize - 0.5,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }
}

