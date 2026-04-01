import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/news_article.dart';
import '../../providers/news_provider.dart';
import '../../theme/app_colors.dart';
import 'news_detail_screen.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      final news = ref.read(newsProvider);
      news.whenData((state) {
        if (state.hasMore && !state.isLoadingMore) {
          ref.read(newsProvider.notifier).loadMore();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context, newsAsync.valueOrNull),
      body: SafeArea(
        top: false,
        child: newsAsync.when(
          loading: () => const _LoadingView(),
          error: (e, _) => _ErrorView(onRetry: () => ref.read(newsProvider.notifier).refresh()),
          data: (state) => _buildBody(context, state),
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, NewsState? state) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'Market News',
        style: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.nearBlack,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.sort_rounded, color: AppColors.nearBlack),
          tooltip: 'Sort',
          onPressed: state == null ? null : () => _showSortSheet(context, state.sort),
        ),
      ],
      bottom: state == null ? null : _buildFilterBar(state.filter),
    );
  }

  PreferredSize _buildFilterBar(NewsCategory? active) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Column(
        children: [
          Container(height: 1, color: AppColors.borderGrey),
          SizedBox(
            height: 51,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  active: active == null,
                  onTap: () => ref.read(newsProvider.notifier).setFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Crypto',
                  active: active == NewsCategory.crypto,
                  onTap: () => ref.read(newsProvider.notifier).setFilter(NewsCategory.crypto),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Forex',
                  active: active == NewsCategory.forex,
                  onTap: () => ref.read(newsProvider.notifier).setFilter(NewsCategory.forex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sort bottom sheet ───────────────────────────────────────────────────────

  void _showSortSheet(BuildContext context, NewsSortOrder current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sort by',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nearBlack,
                ),
              ),
              const SizedBox(height: 12),
              _SortOption(
                label: 'Latest first',
                icon: Icons.arrow_downward_rounded,
                selected: current == NewsSortOrder.latest,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(newsProvider.notifier).setSort(NewsSortOrder.latest);
                },
              ),
              _SortOption(
                label: 'Oldest first',
                icon: Icons.arrow_upward_rounded,
                selected: current == NewsSortOrder.oldest,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(newsProvider.notifier).setSort(NewsSortOrder.oldest);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, NewsState state) {
    if (state.visible.isEmpty) {
      return _EmptyView(onRetry: () => ref.read(newsProvider.notifier).refresh());
    }

    final hero = state.visible.first;
    final rest = state.visible.skip(1).toList();

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () => ref.read(newsProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Hero card ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _HeroCard(
                article: hero,
                onTap: () => _openDetail(context, hero),
              ),
            ),
          ),

          // ── "Trending" header ──────────────────────────────────────────────
          if (rest.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Row(
                  children: [
                    Text(
                      'Trending News',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${state.total} articles',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Article list ───────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ArticleCard(
                article: rest[i],
                onTap: () => _openDetail(context, rest[i]),
              ),
              childCount: rest.length,
            ),
          ),

          // ── Load more / End ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: state.isLoadingMore
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
                        ),
                      ),
                    )
                  : state.hasMore
                      ? const SizedBox.shrink()
                      : Center(
                          child: Text(
                            'You\'re all caught up',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.mediumGrey,
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, NewsArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _HeroCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 230,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              _NewsImage(url: article.imageUrl, category: article.category),

              // Bottom gradient + text
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 40, 14, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _SourceBadge(source: article.source, category: article.category),
                          const Spacer(),
                          Text(
                            _formatDate(article.publishedAt),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ── Article card (list rows) ──────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _NewsImage(
                      url: article.imageUrl,
                      category: article.category,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.nearBlack,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _SourceBadge(
                            source: article.source,
                            category: article.category,
                            small: true,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${_formatDate(article.publishedAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderGrey),
          ],
        ),
      ),
    );
  }
}

// ── Source badge ──────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final String source;
  final NewsCategory category;
  final bool small;

  const _SourceBadge({
    required this.source,
    required this.category,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = category == NewsCategory.crypto
        ? const Color(0xFF1E88E5)
        : const Color(0xFF43A047);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        source,
        style: GoogleFonts.inter(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── News image with fallback ──────────────────────────────────────────────────

class _NewsImage extends StatelessWidget {
  final String? url;
  final NewsCategory category;

  const _NewsImage({this.url, required this.category});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : _placeholder(),
    );
  }

  Widget _placeholder() {
    final color = category == NewsCategory.crypto
        ? const Color(0xFF1E88E5)
        : const Color(0xFF43A047);
    return Container(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          category == NewsCategory.crypto
              ? Icons.currency_bitcoin_rounded
              : Icons.currency_exchange_rounded,
          color: color.withValues(alpha: 0.5),
          size: 32,
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.nearBlack : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.white : AppColors.mediumGrey,
          ),
        ),
      ),
    );
  }
}

// ── Sort option row ───────────────────────────────────────────────────────────

class _SortOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? AppColors.gold : AppColors.mediumGrey),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.nearBlack : AppColors.mediumGrey,
              ),
            ),
            const Spacer(),
            if (selected) const Icon(Icons.check_rounded, color: AppColors.gold, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Loading / Error / Empty states ───────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading market news…',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.mediumGrey),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.mediumGrey),
            const SizedBox(height: 16),
            Text(
              'Could not load news',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.nearBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.mediumGrey),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.nearBlack,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Try again',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.goldLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.newspaper_rounded, size: 36, color: AppColors.gold),
          ),
          const SizedBox(height: 20),
          Text(
            'No articles found',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.nearBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different filter or check back later.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.mediumGrey),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Refresh',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Utilities ─────────────────────────────────────────────────────────────────

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM, y').format(dt);
}
