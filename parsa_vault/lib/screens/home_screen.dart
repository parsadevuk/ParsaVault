import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/xp_service.dart';
import '../models/user_model.dart';
import '../models/holding_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  List<HoldingModel> _holdings = [];
  Map<String, double> _livePrices = {};
  bool _isLoading = true;
  String _greeting = 'Good morning';

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadData();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    final user = await DatabaseService.instance.getUserById(userId);
    final holdings = await DatabaseService.instance.getHoldings(userId);

    // Fetch live prices for holdings
    final prices = <String, double>{};
    for (final holding in holdings) {
      final isCrypto = ApiService.popularCryptos.any(
        (c) => c['symbol'] == holding.symbol,
      );
      double? price;
      if (isCrypto) {
        price = await ApiService.instance.fetchCryptoPrice(holding.symbol);
      } else {
        price = await ApiService.instance.fetchStockPrice(holding.symbol);
      }
      if (price != null) {
        prices[holding.symbol] = price;
      }
    }

    if (!mounted) return;
    setState(() {
      _user = user;
      _holdings = holdings;
      _livePrices = prices;
      _isLoading = false;
    });
  }

  double get _holdingsWorth {
    double total = 0;
    for (final h in _holdings) {
      final price = _livePrices[h.symbol] ?? h.averageBuyPrice;
      total += h.shares * price;
    }
    return total;
  }

  double get _totalPortfolioValue {
    return (_user?.cashBalance ?? 0) + _holdingsWorth;
  }

  @override
  Widget build(BuildContext context) {
    final xpService = XpService.instance;
    final userLevel = _user?.level ?? 1;
    final userXp = _user?.xp ?? 0;
    final nextLevelXp = xpService.getXpForNextLevel(userLevel);

    final xpProgress = xpService.getProgressToNextLevel(userXp, userLevel);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.goldAccent),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.goldAccent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_greeting, ${_user?.fullName.split(' ').first ?? 'Trader'}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Total portfolio value card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.goldAccent,
                              width: 4,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Portfolio Value',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${_totalPortfolioValue.toStringAsFixed(2)}',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cash balance and holdings worth
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Cash Balance',
                              value:
                                  '\$${(_user?.cashBalance ?? 0).toStringAsFixed(2)}',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              label: 'Holdings Worth',
                              value:
                                  '\$${_holdingsWorth.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // XP progress bar
                      Text(
                        'Level $userLevel — $userXp / $nextLevelXp XP',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: xpProgress,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.goldAccent,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Your holdings
                      Text(
                        'Your Holdings',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_holdings.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'You have no holdings yet.\nHead to Markets to start trading.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.secondaryText,
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      else
                        ...(_holdings.map((h) => _HoldingCard(
                              holding: h,
                              livePrice: _livePrices[h.symbol],
                            ))),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingCard extends StatelessWidget {
  final HoldingModel holding;
  final double? livePrice;

  const _HoldingCard({required this.holding, this.livePrice});

  @override
  Widget build(BuildContext context) {
    final currentPrice = livePrice ?? holding.averageBuyPrice;
    final changePercent = holding.averageBuyPrice > 0
        ? ((currentPrice - holding.averageBuyPrice) / holding.averageBuyPrice) *
            100
        : 0.0;
    final isPositive = changePercent >= 0;

    return Container(
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
                holding.symbol.substring(0, holding.symbol.length > 2 ? 2 : holding.symbol.length),
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
                  holding.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  '${holding.symbol} · ${holding.shares.toStringAsFixed(holding.shares == holding.shares.roundToDouble() ? 0 : 4)} shares',
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
                '\$${currentPrice.toStringAsFixed(2)}',
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
    );
  }
}
