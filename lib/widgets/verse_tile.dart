import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer_book_model.dart';
import '../providers/prayer_book_provider.dart';
import '../utils/app_colors.dart';

class ParagraphTile extends StatelessWidget {
  final Paragraph paragraph;
  final double? fontSizeOverride;

  const ParagraphTile({
    super.key,
    required this.paragraph,
    this.fontSizeOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (paragraph.isEmpty) return const SizedBox(height: 10);

    final provider = context.watch<PrayerBookProvider>();
    final fontSize = fontSizeOverride ?? provider.fontSize;

    if (paragraph.isHeading) return _HeadingTile(text: paragraph.text);
    if (paragraph.isRubric) {
      return _RubricTile(text: paragraph.text, fontSize: fontSize);
    }

    return _ContentTile(paragraph: paragraph, fontSize: fontSize);
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
  final double fontSize;

  const _ContentTile({required this.paragraph, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        paragraph.text,
        style: GoogleFonts.lato(
          fontSize: fontSize,
          height: 1.75,
          color: AppColors.textPrimary,
          fontStyle: paragraph.isScripture ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}
