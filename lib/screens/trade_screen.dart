import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/xp_service.dart';
import '../models/holding_model.dart';
import '../models/transaction_model.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 64,
                  color: AppColors.goldAccent.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select an asset from Markets to trade',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TradeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> asset;

  const TradeDetailScreen({super.key, required this.asset});

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  bool _isBuy = true;
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  List<double> _chartData = [];
  double? _currentPrice;
  double? _changePercent;

  @override
  void initState() {
    super.initState();
    _currentPrice = (widget.asset['price'] as num?)?.toDouble();
    _changePercent = (widget.asset['changePercent'] as num?)?.toDouble();
    _loadChartData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    final symbol = widget.asset['symbol'] as String;
    final isCrypto = widget.asset['isCrypto'] == true;

    List<double>? data;
    if (!isCrypto) {
      data = await ApiService.instance.fetchStockIntraday(symbol);
    }

    if (data == null || data.isEmpty) {
      // Generate sample data if API doesn't return intraday
      final basePrice = _currentPrice ?? 100.0;
      data = List.generate(24, (i) {
        final factor = 1.0 + (i % 3 == 0 ? 0.01 : -0.005) * (i % 5);
        return basePrice * factor;
      });
    }

    if (!mounted) return;
    setState(() => _chartData = data!);
  }

  double get _estimatedTotal {
    final shares = double.tryParse(_amountController.text) ?? 0;
    return shares * (_currentPrice ?? 0);
  }

  Future<void> _confirmTrade() async {
    final shares = double.tryParse(_amountController.text);
    if (shares == null || shares <= 0) {
      setState(() => _errorMessage = 'Enter a valid number of shares.');
      return;
    }

    if (_currentPrice == null || _currentPrice == 0) {
      setState(() => _errorMessage = 'Price is not available.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      final user = await DatabaseService.instance.getUserById(userId);
      if (user == null) return;

      final totalCost = shares * _currentPrice!;
      final symbol = widget.asset['symbol'] as String;
      final name = widget.asset['name'] as String;

      if (_isBuy) {
        if (totalCost > user.cashBalance) {
          setState(() {
            _errorMessage = 'Insufficient balance. You have \$${user.cashBalance.toStringAsFixed(2)}.';
            _isLoading = false;
          });
          return;
        }

        // Update balance
        await DatabaseService.instance.updateUserBalance(
          userId,
          user.cashBalance - totalCost,
        );

        // Update holding
        final existing =
            await DatabaseService.instance.getHolding(userId, symbol);
        if (existing != null) {
          final newShares = existing.shares + shares;
          final newAvg = ((existing.shares * existing.averageBuyPrice) +
                  (shares * _currentPrice!)) /
              newShares;
          await DatabaseService.instance.upsertHolding(
            existing.copyWith(shares: newShares, averageBuyPrice: newAvg),
          );
        } else {
          await DatabaseService.instance.upsertHolding(
            HoldingModel(
              userId: userId,
              symbol: symbol,
              name: name,
              shares: shares,
              averageBuyPrice: _currentPrice!,
            ),
          );
        }
      } else {
        // Sell
        final existing =
            await DatabaseService.instance.getHolding(userId, symbol);
        if (existing == null || existing.shares < shares) {
          setState(() {
            _errorMessage = 'Insufficient shares. You have ${existing?.shares.toStringAsFixed(4) ?? '0'} shares.';
            _isLoading = false;
          });
          return;
        }

        await DatabaseService.instance.updateUserBalance(
          userId,
          user.cashBalance + totalCost,
        );

        final newShares = existing.shares - shares;
        await DatabaseService.instance.upsertHolding(
          existing.copyWith(shares: newShares),
        );
      }

      // Save transaction
      await DatabaseService.instance.addTransaction(
        TransactionModel(
          userId: userId,
          symbol: symbol,
          name: name,
          type: _isBuy ? 'buy' : 'sell',
          shares: shares,
          pricePerShare: _currentPrice!,
          totalValue: totalCost,
        ),
      );

      // Award XP
      final isProfitable = !_isBuy &&
          (_currentPrice! >
              ((await DatabaseService.instance.getHolding(userId, symbol))
                      ?.averageBuyPrice ??
                  _currentPrice!));

      await XpService.instance.awardXp(
        userId: userId,
        currentXp: user.xp,
        isProfitable: isProfitable,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_isBuy ? 'Bought' : 'Sold'} ${shares.toStringAsFixed(shares == shares.roundToDouble() ? 0 : 4)} shares of $symbol',
          ),
          backgroundColor: _isBuy ? AppColors.successGreen : AppColors.dangerRed,
        ),
      );

      _amountController.clear();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Trade failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = _currentPrice ?? 0.0;
    final changePercent = _changePercent ?? 0.0;
    final isPositive = changePercent >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.asset['name'] as String,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.asset['symbol']}${widget.asset['isCrypto'] == true ? ' · Crypto' : ' · Stock'}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isPositive
                    ? AppColors.successGreen
                    : AppColors.dangerRed,
              ),
            ),
            const SizedBox(height: 24),
            // Chart
            if (_chartData.isNotEmpty)
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _chartData.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value);
                        }).toList(),
                        isCurved: true,
                        color: AppColors.goldAccent,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.goldAccent.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Buy/Sell toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBuy = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isBuy ? AppColors.goldAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isBuy ? AppColors.goldAccent : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Buy',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isBuy ? Colors.white : AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBuy = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color:
                            !_isBuy ? AppColors.goldAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              !_isBuy ? AppColors.goldAccent : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Sell',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                !_isBuy ? Colors.white : AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Number of shares',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(
              'Estimated total: \$${_estimatedTotal.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.dangerRed,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmTrade,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isBuy ? 'Confirm Buy' : 'Confirm Sell'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
