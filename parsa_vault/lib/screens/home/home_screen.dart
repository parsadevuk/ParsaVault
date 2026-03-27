import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/xp_progress_bar.dart';
import '../../widgets/common/asset_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../trade/trade_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final portfolio = ref.watch(portfolioProvider);
    final market = ref.watch(marketProvider);

    if (user == null) return const SizedBox.shrink();

    final totalValue = ref.read(portfolioProvider.notifier).getPortfolioValue();
    final holdingsValue = ref.read(portfolioProvider.notifier).getHoldingsValue();

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
            // Header
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${AppFormatters.greeting()},',
                              style: AppTextStyles.caption),
                          Text(user.firstName, style: AppTextStyles.greetingText),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const LeaderboardScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events_outlined,
                              size: 22, color: AppColors.gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Portfolio card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _PortfolioCard(
                  totalValue: totalValue,
                  cashBalance: user.cashBalance,
                  holdingsValue: holdingsValue,
                ),
              ),
            ),

            // XP bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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

            // Holdings title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: Text('My Holdings', style: AppTextStyles.sectionHeading),
              ),
            ),

            // Holdings list or empty
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
                    final pnl = currentValue - (h.shares * h.averageBuyPrice);
                    return Column(
                      children: [
                        AssetTile(
                          asset: asset,
                          sharesOwned: h.shares,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TradeScreen(asset: asset),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 80, right: 24, bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Value: ${AppFormatters.currency(currentValue)}',
                                  style: AppTextStyles.caption),
                              Text(
                                '${pnl >= 0 ? '+' : ''}${AppFormatters.currency(pnl)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: pnl >= 0
                                      ? AppColors.successGreen
                                      : AppColors.dangerRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, indent: 80),
                      ],
                    );
                  },
                  childCount: portfolio.holdings.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final double totalValue;
  final double cashBalance;
  final double holdingsValue;

  const _PortfolioCard({
    required this.totalValue,
    required this.cashBalance,
    required this.holdingsValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softWhite,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.gold, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Portfolio Value',
              style: AppTextStyles.caption.copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(AppFormatters.currency(totalValue), style: AppTextStyles.priceLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  label: 'Cash',
                  value: AppFormatters.currency(cashBalance),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniCard(
                  label: 'Holdings',
                  value: AppFormatters.currency(holdingsValue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  const _MiniCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.priceMedium.copyWith(fontSize: 16),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
