import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer_book_model.dart';
import '../providers/prayer_book_provider.dart';
import '../utils/app_colors.dart';

class ParagraphTile extends StatelessWidget {
  final Paragraph paragraph;
  final int pageNum;
  final int paragraphIndex;
  final int sectionId;
  final String sectionTitle;
  final String? subsectionId;
  final String? subsectionTitle;
  final double? fontSizeOverride;

  const ParagraphTile({
    super.key,
    required this.paragraph,
    required this.pageNum,
    required this.paragraphIndex,
    required this.sectionId,
    required this.sectionTitle,
    this.subsectionId,
    this.subsectionTitle,
    this.fontSizeOverride,
  });

  String get _favKey => '${pageNum}_$paragraphIndex';

  @override
  Widget build(BuildContext context) {
    if (paragraph.isEmpty) return const SizedBox(height: 10);

    final provider = context.watch<PrayerBookProvider>();
    final isFav = provider.isFavourite(_favKey);
    final fontSize = fontSizeOverride ?? provider.fontSize;

    if (paragraph.isHeading) return _HeadingTile(text: paragraph.text);
    if (paragraph.isRubric) {
      return _RubricTile(text: paragraph.text, fontSize: fontSize);
    }

    return _ContentTile(
      paragraph: paragraph,
      isFav: isFav,
      fontSize: fontSize,
      onFavToggle: () => provider.toggleFavourite(
        favKey: _favKey,
        pageNum: pageNum,
        paragraphIndex: paragraphIndex,
        paragraphText: paragraph.text,
        paragraphType: paragraph.type,
        sectionId: sectionId,
        sectionTitle: sectionTitle,
        subsectionId: subsectionId,
        subsectionTitle: subsectionTitle,
      ),
    );
  }
}

// ── Heading ───────────────────────────────────────────────────────────────────

class _HeadingTile extends StatelessWidget {
  final String text;
  const _HeadingTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(
        text,
        style: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.headingColor,
          height: 1.4,
        ),
      ),
    );
  }
}

// ── Rubric / Instruction (Amabwiriza) ─────────────────────────────────────────

class _RubricTile extends StatelessWidget {
  final String text;
  final double fontSize;
  const _RubricTile({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: GoogleFonts.lato(
          fontSize: fontSize - 1,
          color: AppColors.rubricColor,
          fontStyle: FontStyle.italic,
          height: 1.6,
        ),
      ),
    );
  }
}

// ── Content tile ──────────────────────────────────────────────────────────────

class _ContentTile extends StatelessWidget {
  final Paragraph paragraph;
  final bool isFav;
  final double fontSize;
  final VoidCallback onFavToggle;

  const _ContentTile({
    required this.paragraph,
    required this.isFav,
    required this.fontSize,
    required this.onFavToggle,
  });

  // Scripture: no bg box — just green text color. Only collect/response/creed/canticle get containers.
  Color get _bgColor {
    if (paragraph.isCollect) return AppColors.collectBg;
    if (paragraph.isResponse) return AppColors.responseBg;
    if (paragraph.isCreed || paragraph.isCanticle) return const Color(0xFFF5F0FB);
    return Colors.transparent;
  }

  Color get _leftBorderColor {
    if (paragraph.isCollect) return AppColors.primary;
    if (paragraph.isResponse) return AppColors.primaryLight;
    if (paragraph.isCreed || paragraph.isCanticle) return const Color(0xFF8A6BBB);
    return Colors.transparent;
  }

  // "All" speaker is not labeled — only minister (Um.) and congregation (It.)
  String get _speakerLabel {
    switch (paragraph.speaker) {
      case 'minister':
        return 'Um.';
      case 'congregation':
        return 'It.';
      default:
        return '';
    }
  }

  Color get _speakerColor {
    switch (paragraph.speaker) {
      case 'minister':
        return AppColors.primary;
      case 'congregation':
        return AppColors.primaryDark;
      default:
        return AppColors.grey600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBackground = _bgColor != Colors.transparent;
    final hasBorder = _leftBorderColor != Colors.transparent;
    final label = _speakerLabel;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _speakerColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              paragraph.text,
              style: GoogleFonts.lato(
                fontSize: fontSize,
                height: 1.75,
                // Scripture keeps its green text color; no container box
                color: paragraph.isScripture
                    ? AppColors.scriptureColor
                    : AppColors.textPrimary,
                fontWeight: paragraph.isResponse
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onFavToggle,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isFav ? Icons.bookmark : Icons.bookmark_border,
                  key: ValueKey(isFav),
                  size: 18,
                  color: isFav ? AppColors.favourite : AppColors.grey400,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (hasBackground || hasBorder) {
      content = Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(8),
          border: hasBorder
              ? Border(left: BorderSide(color: _leftBorderColor, width: 3))
              : null,
        ),
        child: content,
      );
    }

    return content;
  }
}
