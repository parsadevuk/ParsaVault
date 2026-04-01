import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/news_article.dart';
import '../../theme/app_colors.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero image with overlaid back + bookmark ─────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.nearBlack,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(article: article),
            ),
          ),

          // ── Article content ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source + date row
                  Row(
                    children: [
                      _CategoryBadge(article: article),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('d MMMM y · HH:mm').format(article.publishedAt.toLocal()),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    article.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.nearBlack,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Gold divider
                  Container(
                    width: 36,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Body text
                  if (article.description.isNotEmpty)
                    Text(
                      article.description,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.nearBlack,
                        height: 1.7,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Source attribution — taps open article in browser
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(article.url);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Read full article on ${article.source}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.gold,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero image ────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final NewsArticle article;
  const _HeroImage({required this.article});

  @override
  Widget build(BuildContext context) {
    final color = article.category == NewsCategory.crypto
        ? const Color(0xFF1E88E5)
        : const Color(0xFF43A047);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
          Image.network(
            article.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _colorPlaceholder(color),
          )
        else
          _colorPlaceholder(color),

        // Bottom fade so AppBar blends with content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorPlaceholder(Color color) {
    return Container(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          article.category == NewsCategory.crypto
              ? Icons.currency_bitcoin_rounded
              : Icons.currency_exchange_rounded,
          size: 64,
          color: color.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ── Category badge ────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final NewsArticle article;
  const _CategoryBadge({required this.article});

  @override
  Widget build(BuildContext context) {
    final color = article.category == NewsCategory.crypto
        ? const Color(0xFF1E88E5)
        : const Color(0xFF43A047);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        article.source,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
