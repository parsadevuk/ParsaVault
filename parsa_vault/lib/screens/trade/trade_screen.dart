import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/asset.dart';
import '../../models/holding.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/market_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/buttons/gold_button.dart';

class TradeScreen extends ConsumerStatefulWidget {
  final Asset asset;

  const TradeScreen({super.key, required this.asset});

  @override
  ConsumerState<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends ConsumerState<TradeScreen> {
  bool _isBuying = true;
  final _sharesCtrl = TextEditingController();
  String? _inputError;
  String _selectedRange = '1D';

  @override
  void dispose() {
    _sharesCtrl.dispose();
    super.dispose();
  }

  Asset get _liveAsset =>
      ref.read(marketProvider).findBySymbol(widget.asset.symbol) ??
      widget.asset;

  Holding? get _holding => ref
      .read(portfolioProvider)
      .holdings
      .where((h) => h.symbol == widget.asset.symbol)
      .firstOrNull;

  double get _shares =>
      double.tryParse(_sharesCtrl.text.trim()) ?? 0;

  double get _estimatedTotal => _shares * _liveAsset.currentPrice;

  void _validate() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() {
      if (_sharesCtrl.text.trim().isEmpty || _shares <= 0) {
        _inputError = 'Enter how many shares you want.';
      } else if (_isBuying && _estimatedTotal > user.cashBalance) {
        _inputError =
            "Not enough cash. You have ${AppFormatters.currency(user.cashBalance)}.";
      } else if (!_isBuying) {
        final owned = _holding?.shares ?? 0;
        if (_shares > owned) {
          _inputError =
              'You only own ${AppFormatters.shares(owned)} shares.';
        } else {
          _inputError = null;
        }
      } else {
        _inputError = null;
      }
    });
  }

  Future<void> _confirmTrade() async {
    _validate();
    if (_inputError != null) return;

    final asset = _liveAsset;
    final portfolio = ref.read(portfolioProvider.notifier);

    bool success;
    if (_isBuying) {
      success = await portfolio.buy(
        symbol: asset.symbol,
        assetName: asset.name,
        assetType: asset.type,
        shares: _shares,
        currentPrice: asset.currentPrice,
      );
    } else {
      success = await portfolio.sell(
        symbol: asset.symbol,
        assetName: asset.name,
        assetType: asset.type,
        shares: _shares,
        currentPrice: asset.currentPrice,
      );
    }

    if (!mounted) return;

    if (success) {
      final msg = ref.read(portfolioProvider).successMessage ?? 'Trade done.';
      ref.read(portfolioProvider.notifier).clearMessages();
      _sharesCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.nearBlack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error = ref.read(portfolioProvider).error ?? 'Something went wrong.';
      ref.read(portfolioProvider.notifier).clearMessages();
      setState(() => _inputError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = ref.watch(marketProvider).findBySymbol(widget.asset.symbol) ??
        widget.asset;
    final user = ref.watch(authProvider).user;
    final portfolioState = ref.watch(portfolioProvider);
    final holding = portfolioState.holdings
        .where((h) => h.symbol == asset.symbol)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.nearBlack, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(asset.symbol, style: AppTextStyles.cardTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asset name
            Text(asset.name,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.mediumGrey)),
            const SizedBox(height: 8),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(AppFormatters.price(asset.currentPrice),
                    style: AppTextStyles.priceLarge),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: asset.isUp
                        ? AppColors.successGreen.withValues(alpha: 0.1)
                        : AppColors.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppFormatters.percentage(asset.changePercent24h),
                    style: asset.isUp
                        ? AppTextStyles.percentageUp
                        : AppTextStyles.percentageDown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${asset.isUp ? '+' : ''}${AppFormatters.currency(asset.change24h)} today',
              style: AppTextStyles.caption,
            ),

            const SizedBox(height: 20),

            // Chart
            _PriceChart(asset: asset, selectedRange: _selectedRange),

            // Time range selector
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['1D', '1W', '1M', '3M'].map((range) {
                  final active = _selectedRange == range;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRange = range),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? AppColors.gold : AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        range,
                        style: AppTextStyles.caption.copyWith(
                          color:
                              active ? Colors.white : AppColors.mediumGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Buy / Sell toggle
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _ToggleOption(
                    label: 'Buy',
                    active: _isBuying,
                    onTap: () => setState(() => _isBuying = true),
                  ),
                  _ToggleOption(
                    label: 'Sell',
                    active: !_isBuying,
                    onTap: () => setState(() => _isBuying = false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Input
            Text('Number of shares', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sharesCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: AppTextStyles.priceLarge.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
              onChanged: (_) => _validate(),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: AppTextStyles.priceLarge
                    .copyWith(fontSize: 28, color: AppColors.borderGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.gold, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.dangerRed, width: 1.5),
                ),
                errorText: _inputError,
                errorStyle: AppTextStyles.errorText,
              ),
            ),

            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Price per share',
                    value: AppFormatters.price(asset.currentPrice),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Estimated total',
                    value: AppFormatters.currency(_estimatedTotal),
                    bold: true,
                  ),
                  const Divider(height: 16),
                  if (_isBuying && user != null)
                    _SummaryRow(
                      label: 'Cash available',
                      value: AppFormatters.currency(user.cashBalance),
                    )
                  else if (!_isBuying && holding != null)
                    _SummaryRow(
                      label: 'Shares owned',
                      value: AppFormatters.shares(holding.shares),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            GoldButton(
              label: _isBuying ? 'Confirm Buy' : 'Confirm Sell',
              onPressed: _confirmTrade,
              isLoading: portfolioState.isLoading,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PriceChart extends StatelessWidget {
  final Asset asset;
  final String selectedRange;

  const _PriceChart({required this.asset, required this.selectedRange});

  @override
  Widget build(BuildContext context) {
    if (asset.priceHistory.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    final spots = asset.priceHistory
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.price))
        .toList();

    final minY =
        spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.998;
    final maxY =
        spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.002;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: asset.isUp ? AppColors.successGreen : AppColors.dangerRed,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (asset.isUp ? AppColors.successGreen : AppColors.dangerRed)
                        .withValues(alpha: 0.2),
                    (asset.isUp ? AppColors.successGreen : AppColors.dangerRed)
                        .withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  AppFormatters.price(s.y),
                  AppTextStyles.captionBold.copyWith(color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: active ? Colors.white : AppColors.mediumGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: bold ? AppTextStyles.label : AppTextStyles.bodyMedium),
        Text(value,
            style: bold
                ? AppTextStyles.label.copyWith(color: AppColors.nearBlack)
                : AppTextStyles.bodyMedium),
      ],
    );
  }
}
