import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prayer_book_model.dart';
import '../providers/prayer_book_provider.dart';
import '../utils/app_colors.dart';
import 'chapter_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerBookProvider>();
    final favourites = provider.favourites;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        title: Text(
          'Byabitswe',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: favourites.isNotEmpty
            ? [
                TextButton(
                  onPressed: () => _confirmClearAll(context, provider),
                  child: Text(
                    'Siba Byose',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: AppColors.rubricColor,
                    ),
                  ),
                ),
              ]
            : null,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: favourites.isEmpty
          ? _EmptyFavourites()
          : _FavouriteList(favourites: favourites, provider: provider),
    );
  }

  void _confirmClearAll(BuildContext context, PrayerBookProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Siba ibyo bitswe byose?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Bizakuraho imigabane yose mwabitswe.',
          style: GoogleFonts.lato(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
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
              for (final fav in List.from(provider.favourites)) {
                provider.removeFavourite(fav.favKey);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Siba Byose',
              style: GoogleFonts.lato(
                color: AppColors.rubricColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyFavourites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.favourite.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border,
                size: 38, color: AppColors.favourite),
          ),
          const SizedBox(height: 20),
          Text(
            'Nta kintu nabwo kibitswe',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Kanda akamaro k'agapapuro ku migabane\nugusome kugira ngo ubibitseho hano.",
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppColors.textHint,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Favourites list ───────────────────────────────────────────────────────────

class _FavouriteList extends StatelessWidget {
  final List<FavouriteItem> favourites;
  final PrayerBookProvider provider;

  const _FavouriteList({
    required this.favourites,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: favourites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _FavouriteCard(
        fav: favourites[index],
        provider: provider,
      ),
    );
  }
}

class _FavouriteCard extends StatelessWidget {
  final FavouriteItem fav;
  final PrayerBookProvider provider;

  const _FavouriteCard({required this.fav, required this.provider});

  void _navigateTo(BuildContext context) {
    final fp = provider.pageAtNumber(fav.pageNum);
    if (fp == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PageReadingScreen(flatPage: fp)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(fav.favKey),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.rubricColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.rubricColor),
      ),
      onDismissed: (_) => provider.removeFavourite(fav.favKey),
      child: GestureDetector(
        onTap: () => _navigateTo(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: const BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark,
                        size: 14, color: AppColors.favourite),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fav.breadcrumb,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => provider.removeFavourite(fav.favKey),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.grey400),
                    ),
                  ],
                ),
              ),
              // Paragraph text
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Text(
                  fav.paragraphText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    height: 1.7,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    _TypeBadge(type: fav.paragraphType),
                    const Spacer(),
                    Text(
                      'Paji ${fav.pageNum}  ·  ',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        color: AppColors.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(fav.savedAt),
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: GoogleFonts.lato(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
