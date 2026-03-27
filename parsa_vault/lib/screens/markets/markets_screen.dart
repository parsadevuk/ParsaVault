import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/market_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/asset.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/asset_tile.dart';
import '../trade/trade_screen.dart';

class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});

  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Asset> _filter(List<Asset> assets) {
    if (_searchQuery.isEmpty) return assets;
    final q = _searchQuery.toLowerCase();
    return assets
        .where((a) =>
            a.symbol.toLowerCase().contains(q) ||
            a.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final portfolio = ref.watch(portfolioProvider);

    final stocks = _filter(market.stocks);
    final cryptos = _filter(market.cryptos);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('Markets', style: AppTextStyles.screenTitle),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search stocks and crypto',
                  hintStyle: AppTextStyles.inputPlaceholder,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.mediumGrey, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() => _searchQuery = ''),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.mediumGrey, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.gold, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: TabBar(
                controller: _tabController,
                tabs: const [Tab(text: 'Stocks'), Tab(text: 'Crypto')],
              ),
            ),

            // List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AssetList(
                    assets: stocks,
                    portfolio: portfolio,
                    emptyMessage: _searchQuery.isEmpty
                        ? 'Loading stocks...'
                        : 'Nothing found for "$_searchQuery".',
                  ),
                  _AssetList(
                    assets: cryptos,
                    portfolio: portfolio,
                    emptyMessage: _searchQuery.isEmpty
                        ? 'Loading crypto...'
                        : 'Nothing found for "$_searchQuery".',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetList extends StatelessWidget {
  final List<Asset> assets;
  final PortfolioState portfolio;
  final String emptyMessage;

  const _AssetList({
    required this.assets,
    required this.portfolio,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.mediumGrey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: assets.length,
      separatorBuilder: (_, i) =>
          const Divider(height: 1, indent: 80, endIndent: 24),
      itemBuilder: (context, i) {
        final asset = assets[i];
        final holding = portfolio.holdings
            .where((h) => h.symbol == asset.symbol)
            .firstOrNull;
        return AssetTile(
          asset: asset,
          sharesOwned: holding?.shares,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TradeScreen(asset: asset)),
          ),
        );
      },
    );
  }
}
