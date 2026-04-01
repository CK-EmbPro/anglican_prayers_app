import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer_book_model.dart';
import '../providers/prayer_book_provider.dart';
import '../utils/app_colors.dart';

class VerseTile extends StatelessWidget {
  final Verse verse;
  final int sectionId;
  final String sectionTitle;
  final String sectionSlug;
  final int chapterId;
  final String chapterTitle;
  final double? fontSizeOverride;

  const VerseTile({
    super.key,
    required this.verse,
    required this.sectionId,
    required this.sectionTitle,
    required this.sectionSlug,
    required this.chapterId,
    required this.chapterTitle,
    this.fontSizeOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (verse.isEmpty) return const SizedBox(height: 10);

    final provider = context.watch<PrayerBookProvider>();
    final isFav = provider.isFavourite(verse.id);
    final fontSize = fontSizeOverride ?? provider.fontSize;

    if (verse.isHeading) return _HeadingTile(text: verse.text);
    if (verse.isRubric) return _RubricTile(text: verse.text, fontSize: fontSize);

    return _ContentTile(
      verse: verse,
      isFav: isFav,
      fontSize: fontSize,
      onFavToggle: () => provider.toggleFavourite(
        verseId: verse.id,
        verseText: verse.text,
        verseType: verse.type,
        sectionId: sectionId,
        sectionTitle: sectionTitle,
        sectionSlug: sectionSlug,
        chapterId: chapterId,
        chapterTitle: chapterTitle,
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

// ── Rubric / Instruction ──────────────────────────────────────────────────────

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

// ── Content tile (prayer, response, collect, scripture, creed) ────────────────

class _ContentTile extends StatelessWidget {
  final Verse verse;
  final bool isFav;
  final double fontSize;
  final VoidCallback onFavToggle;

  const _ContentTile({
    required this.verse,
    required this.isFav,
    required this.fontSize,
    required this.onFavToggle,
  });

  Color get _bgColor {
    if (verse.isCollect) return AppColors.collectBg;
    if (verse.isResponse) return AppColors.responseBg;
    if (verse.isScripture) return const Color(0xFFF0F7EE);
    if (verse.isCreed || verse.isCanticle) return const Color(0xFFF5F0FB);
    return Colors.transparent;
  }

  Color get _leftBorderColor {
    if (verse.isCollect) return AppColors.primary;
    if (verse.isResponse) return AppColors.primaryLight;
    if (verse.isScripture) return AppColors.scriptureColor;
    if (verse.isCreed || verse.isCanticle) return const Color(0xFF8A6BBB);
    return Colors.transparent;
  }

  String get _speakerLabel {
    switch (verse.speaker) {
      case 'minister':
        return 'M.';
      case 'congregation':
        return 'C.';
      case 'all':
        return 'All';
      default:
        return '';
    }
  }

  Color get _speakerColor {
    switch (verse.speaker) {
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
              verse.text,
              style: GoogleFonts.lato(
                fontSize: fontSize,
                height: 1.75,
                color: verse.isScripture
                    ? AppColors.scriptureColor
                    : AppColors.textPrimary,
                fontWeight: verse.isResponse
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
              ? Border(
                  left: BorderSide(color: _leftBorderColor, width: 3),
                )
              : null,
        ),
        child: content,
      );
    }

    return content;
  }
}
