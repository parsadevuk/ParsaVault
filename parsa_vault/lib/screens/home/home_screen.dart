import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/xp_progress_bar.dart';
import '../../widgets/common/empty_state.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../trade/trade_screen.dart';

// ── Background image per country ─────────────────────────────────────────────

String _backgroundForCountry(String country) {
  switch (country.trim().toLowerCase()) {
    case 'uk':
    case 'united kingdom':
    case 'england':
      return 'assets/images/home_bg_london.png';
    default:
      return 'assets/images/home_bg_london.png'; // fallback until more are added
  }
}

// ── Home Screen ───────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final portfolio = ref.watch(portfolioProvider);
    final market = ref.watch(marketProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider);

    if (user == null) return const SizedBox.shrink();

    final totalValue =
        ref.read(portfolioProvider.notifier).getPortfolioValue();
    final holdingsValue =
        ref.read(portfolioProvider.notifier).getHoldingsValue();

    // Top 3 leaderboard users (exclude self)
    final top3 = leaderboardAsync.whenData((users) =>
        users.where((u) => u.id != user.id).take(3).toList());

    return Scaffold(
      backgroundColor: AppColors.white,
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async {
          ref.read(marketProvider.notifier).refresh();
          await ref.read(portfolioProvider.notifier).loadAll();
        },
        child: CustomScrollView(
          slivers: [
            // ── Hero header card ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _HeroHeader(
                user: user,
                totalValue: totalValue,
                holdingsValue: holdingsValue,
                top3: top3.value ?? [],
                onLeaderboard: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen()),
                ),
              ),
            ),

            // ── XP bar ───────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: XpProgressBar(xp: user.xp, level: user.level),
                ),
              ),
            ),

            // ── Holdings title ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: Text('My Holdings',
                    style: AppTextStyles.sectionHeading),
              ),
            ),

            // ── Holdings list or empty state ──────────────────────────────────
            if (portfolio.holdings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No holdings yet.',
                  body: 'Head to Markets and make your first trade.',
                  buttonLabel: 'Go to Markets',
                  onButtonTap: () {
                    ref.read(navigationIndexProvider.notifier).state = 1;
                  },
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final h = portfolio.holdings[i];
                    final asset = market.findBySymbol(h.symbol);
                    if (asset == null) return const SizedBox.shrink();

                    final currentValue = h.shares * asset.currentPrice;
                    final pnlAmount =
                        (asset.currentPrice - h.averageBuyPrice) * h.shares;
                    final pnlPercent =
                        ((asset.currentPrice - h.averageBuyPrice) /
                                h.averageBuyPrice) *
                            100;
                    final isProfitable = pnlAmount >= 0;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => TradeScreen(asset: asset)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: asset.isStock
                                        ? AppColors.lightGrey
                                        : AppColors.goldLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      asset.isStock
                                          ? Icons.show_chart
                                          : Icons.currency_bitcoin,
                                      size: 22,
                                      color: asset.isStock
                                          ? AppColors.nearBlack
                                          : AppColors.gold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(h.symbol,
                                          style: AppTextStyles.label),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${AppFormatters.shares(h.shares)} shares',
                                        style: AppTextStyles.caption,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Avg ${AppFormatters.price(h.averageBuyPrice)}',
                                        style: AppTextStyles.caption
                                            .copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(AppFormatters.currency(currentValue),
                                        style: AppTextStyles.priceSmall),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isProfitable
                                            ? AppColors.successGreen
                                                .withValues(alpha: 0.1)
                                            : AppColors.dangerRed
                                                .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${isProfitable ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                                        style: AppTextStyles.caption.copyWith(
                                          color: isProfitable
                                              ? AppColors.successGreen
                                              : AppColors.dangerRed,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${isProfitable ? '+' : ''}${AppFormatters.currency(pnlAmount)}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: isProfitable
                                            ? AppColors.successGreen
                                            : AppColors.dangerRed,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 80),
                      ],
                    );
                  },
                  childCount: portfolio.holdings.length,
                ),
              ),

            SliverToBoxAdapter(
              child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final User user;
  final double totalValue;
  final double holdingsValue;
  final List<User> top3;
  final VoidCallback onLeaderboard;

  const _HeroHeader({
    required this.user,
    required this.totalValue,
    required this.holdingsValue,
    required this.top3,
    required this.onLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final bgAsset = _backgroundForCountry(user.country);

    // Decode avatar
    ImageProvider? avatarImage;
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      try {
        avatarImage = MemoryImage(base64Decode(user.profilePicture!));
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(bgAsset),
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay — darkest top, lighter bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.25),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  // Top row — leaderboard button right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: onLeaderboard,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1),
                          ),
                          child: const Icon(Icons.emoji_events_outlined,
                              size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Avatar
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                      image: avatarImage != null
                          ? DecorationImage(
                              image: avatarImage, fit: BoxFit.cover)
                          : null,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: avatarImage == null
                        ? Center(
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Full name
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // City, Country
                  Text(
                    '${user.city}, ${user.country}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Top 3 leaderboard avatars
                  if (top3.isNotEmpty) _LeaderboardAvatars(users: top3),
                  const SizedBox(height: 20),

                  // Stats card
                  Container(
                    margin: const EdgeInsets.only(bottom: 0),
                    padding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _StatColumn(
                            label: 'Total',
                            value: AppFormatters.currency(totalValue)),
                        _VertDivider(),
                        _StatColumn(
                            label: 'Holdings',
                            value: AppFormatters.currency(holdingsValue)),
                        _VertDivider(),
                        _StatColumn(
                            label: 'Cash',
                            value: AppFormatters.currency(user.cashBalance)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard mini-avatars ──────────────────────────────────────────────────

class _LeaderboardAvatars extends StatelessWidget {
  final List<User> users;
  const _LeaderboardAvatars({required this.users});

  @override
  Widget build(BuildContext context) {
    // Show up to 3, staggered: outer two smaller+higher, middle larger+lower
    final show = users.take(3).toList();
    const sizes = [32.0, 40.0, 32.0];
    const offsets = [-6.0, 4.0, -6.0]; // vertical offset

    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < show.length; i++)
            Positioned(
              bottom: offsets[i] < 0 ? -offsets[i] : 0,
              left: i == 0 ? 0 : i == 1 ? sizes[0] - 8 : sizes[0] + sizes[1] - 16,
              child: Transform.translate(
                offset: Offset(0, offsets[i]),
                child: _MiniAvatar(user: show[i], size: sizes[i]),
              ),
            ),
          // Invisible sized box to give the stack a proper width
          SizedBox(width: sizes[0] + sizes[1] + sizes[2] - 16, height: 52),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final User user;
  final double size;
  const _MiniAvatar({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(user.profilePicture!));
      } catch (_) {}
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold,
        image: image != null
            ? DecorationImage(image: image, fit: BoxFit.cover)
            : null,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: image == null
          ? Center(
              child: Text(
                user.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }
}

// ── Stat column + divider ─────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.nearBlack,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mediumGrey,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.borderGrey,
    );
  }
}
