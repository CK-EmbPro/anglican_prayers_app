import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer_book_model.dart';
import '../utils/app_colors.dart';

const List<IconData> _sectionIcons = [
  Icons.wb_sunny_outlined,
  Icons.nights_stay_outlined,
  Icons.volunteer_activism_outlined,
  Icons.book_outlined,
  Icons.format_list_bulleted,
  Icons.calendar_month_outlined,
  Icons.water_drop_outlined,
  Icons.article_outlined,
];

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

class SectionCard extends StatelessWidget {
  final Section section;
  final int index;
  final VoidCallback onTap;

  const SectionCard({
    super.key,
    required this.section,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _sectionAccents[index % _sectionAccents.length];
    final icon = _sectionIcons[index % _sectionIcons.length];
    final sectionNumber = (index + 1).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left panel: tinted bg + icon + number ─────────────────────
              Container(
                width: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sectionNumber,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── 3px accent line ────────────────────────────────────────────
              Container(width: 3, color: accent),

              // ── Content ────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        section.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (section.englishTitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          section.englishTitle,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: AppColors.textHint,
                            letterSpacing: 0.2,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _StatPill(
                            icon: Icons.layers_outlined,
                            label: '${section.chapters.length} chapters',
                            accent: accent,
                          ),
                          _StatPill(
                            icon: Icons.format_quote_rounded,
                            label: '${section.totalNonEmptyVerses} verses',
                            accent: accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Chevron ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
