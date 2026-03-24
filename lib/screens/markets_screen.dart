import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _stocks = [];
  List<Map<String, dynamic>> _cryptos = [];
  bool _isLoadingStocks = true;
  bool _isLoadingCryptos = true;
  String? _stockError;
  String? _cryptoError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrices() async {
    _loadStocks();
    _loadCryptos();
  }

  Future<void> _loadStocks() async {
    setState(() {
      _isLoadingStocks = true;
      _stockError = null;
    });

    try {
      final stocks = <Map<String, dynamic>>[];
      for (final stock in ApiService.popularStocks) {
        final quote =
            await ApiService.instance.fetchStockQuote(stock['symbol']!);
        stocks.add({
          'symbol': stock['symbol'],
          'name': stock['name'],
          'price': quote?['price'] ?? 0.0,
          'changePercent': quote?['changePercent'] ?? 0.0,
          'isCrypto': false,
        });
      }
      if (!mounted) return;
      setState(() {
        _stocks = stocks;
        _isLoadingStocks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stockError = 'Failed to load stock prices. Pull to retry.';
        _isLoadingStocks = false;
      });
    }
  }

  Future<void> _loadCryptos() async {
    setState(() {
      _isLoadingCryptos = true;
      _cryptoError = null;
    });

    try {
      final cryptos = <Map<String, dynamic>>[];
      for (final crypto in ApiService.popularCryptos) {
        final quote =
            await ApiService.instance.fetchCryptoQuote(crypto['symbol']!);
        cryptos.add({
          'symbol': crypto['symbol'],
          'name': crypto['name'],
          'price': quote?['price'] ?? 0.0,
          'changePercent': quote?['changePercent'] ?? 0.0,
          'isCrypto': true,
        });
      }
      if (!mounted) return;
      setState(() {
        _cryptos = cryptos;
        _isLoadingCryptos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cryptoError = 'Failed to load crypto prices. Pull to retry.';
        _isLoadingCryptos = false;
      });
    }
  }

  List<Map<String, dynamic>> _filteredList(List<Map<String, dynamic>> list) {
    if (_searchQuery.isEmpty) return list;
    return list
        .where((item) =>
            (item['name'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (item['symbol'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _navigateToTrade(Map<String, dynamic> asset) {
    Navigator.of(context).pushNamed(
      '/trade-detail',
      arguments: asset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Markets',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search markets...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.secondaryText),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.secondaryText),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.goldAccent,
                unselectedLabelColor: AppColors.secondaryText,
                indicatorColor: AppColors.goldAccent,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Stocks'),
                  Tab(text: 'Crypto'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAssetList(
                      items: _filteredList(_stocks),
                      isLoading: _isLoadingStocks,
                      error: _stockError,
                      onRefresh: _loadStocks,
                    ),
                    _buildAssetList(
                      items: _filteredList(_cryptos),
                      isLoading: _isLoadingCryptos,
                      error: _cryptoError,
                      onRefresh: _loadCryptos,
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

  Widget _buildAssetList({
    required List<Map<String, dynamic>> items,
    required bool isLoading,
    required String? error,
    required Future<void> Function() onRefresh,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.goldAccent),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.secondaryText, size: 48),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.goldAccent,
      child: ListView.builder(
        itemCount: items.length,
        padding: const EdgeInsets.only(top: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          final changePercent =
              (item['changePercent'] as num?)?.toDouble() ?? 0.0;
          final isPositive = changePercent >= 0;

          return GestureDetector(
            onTap: () => _navigateToTrade(item),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (item['symbol'] as String).substring(
                          0,
                          (item['symbol'] as String).length > 2 ? 2 : (item['symbol'] as String).length,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        Text(
                          item['symbol'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Text(
                        '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isPositive
                              ? AppColors.successGreen
                              : AppColors.dangerRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
