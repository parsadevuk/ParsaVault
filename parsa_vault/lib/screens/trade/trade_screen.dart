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
  bool _isAmountMode = false; // false = shares, true = $ amount
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String? _inputError;
  String _selectedRange = '1D';

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focusNode.dispose();
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

  // Shares entered or calculated from amount
  double get _shares {
    final raw = double.tryParse(_inputCtrl.text.trim()) ?? 0;
    if (_isAmountMode) {
      final price = _liveAsset.currentPrice;
      return price > 0 ? raw / price : 0;
    }
    return raw;
  }

  double get _estimatedTotal => _shares * _liveAsset.currentPrice;

  void _validate() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final raw = double.tryParse(_inputCtrl.text.trim()) ?? 0;
    setState(() {
      if (_inputCtrl.text.trim().isEmpty || raw <= 0) {
        _inputError = _isAmountMode
            ? 'Enter an amount in dollars.'
            : 'Enter how many shares you want.';
      } else if (_isBuying && _estimatedTotal > user.cashBalance) {
        _inputError =
            "Not enough cash. You have ${AppFormatters.currency(user.cashBalance)}.";
      } else if (!_isBuying) {
        final owned = _holding?.shares ?? 0;
        // Use a tiny tolerance to absorb floating-point rounding from % buttons
        if (_shares > owned + 0.000001) {
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

  void _applyPercentage(double pct) {
    final price = _liveAsset.currentPrice;
    if (_isBuying) {
      // Buy: percentage of available cash balance
      final cash = ref.read(authProvider).user?.cashBalance ?? 0;
      if (cash <= 0 || price <= 0) return;
      if (_isAmountMode) {
        // Floor dollar amount to cents so actual cost never exceeds cash
        final rawAmount = cash * pct;
        final flooredAmount = (rawAmount * 100).floorToDouble() / 100;
        _inputCtrl.text = flooredAmount.toStringAsFixed(2);
      } else {
        // Floor shares to 5dp — never spend more than available cash
        final rawShares = (cash * pct) / price;
        final flooredShares = (rawShares * 100000).floorToDouble() / 100000;
        _inputCtrl.text = _trimTo5(flooredShares);
      }
    } else {
      // Sell: percentage of owned shares
      final owned = _holding?.shares ?? 0;
      if (owned <= 0) return;
      // For 100% (Max), use exact stored value to avoid IEEE 754 drift
      final sharesAmount = pct >= 1.0 ? owned : owned * pct;
      final trimmed = _trimTo5(sharesAmount);

      // If the holding is a tiny fraction that 5dp can't represent (e.g. 0.000001),
      // auto-switch to $ Amount mode so the user can still sell it.
      if (!_isAmountMode && (trimmed.isEmpty || double.tryParse(trimmed) == 0)) {
        setState(() => _isAmountMode = true);
        _inputCtrl.text = (sharesAmount * price).toStringAsFixed(2);
      } else if (_isAmountMode) {
        _inputCtrl.text = (sharesAmount * price).toStringAsFixed(2);
      } else {
        _inputCtrl.text = trimmed;
      }
    }
    _validate();
  }

  String _trimTo5(double val) {
    // Show up to 5 decimal places (floored shares), strip trailing zeros
    final s = val.toStringAsFixed(5);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _confirmTrade() async {
    _validate();
    if (_inputError != null || _shares <= 0) return;

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
      final msg =
          ref.read(portfolioProvider).successMessage ?? 'Trade done.';
      ref.read(portfolioProvider.notifier).clearMessages();
      _inputCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.nearBlack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error =
          ref.read(portfolioProvider).error ?? 'Something went wrong.';
      ref.read(portfolioProvider.notifier).clearMessages();
      setState(() => _inputError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset =
        ref.watch(marketProvider).findBySymbol(widget.asset.symbol) ??
            widget.asset;
    final user = ref.watch(authProvider).user;
    final portfolioState = ref.watch(portfolioProvider);
    final holding = portfolioState.holdings
        .where((h) => h.symbol == asset.symbol)
        .firstOrNull;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
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
          padding: EdgeInsets.fromLTRB(
              24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Asset name
              Text(asset.name,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.mediumGrey)),
              const SizedBox(height: 8),

              // Price + change badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(AppFormatters.price(asset.currentPrice),
                      style: AppTextStyles.priceLarge),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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
              _PriceChart(asset: asset),

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
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.gold
                              : AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          range,
                          style: AppTextStyles.caption.copyWith(
                            color: active
                                ? Colors.white
                                : AppColors.mediumGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Buy / Sell toggle
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _ToggleOption(
                      label: 'Buy',
                      active: _isBuying,
                      onTap: () =>
                          setState(() => _isBuying = true),
                    ),
                    _ToggleOption(
                      label: 'Sell',
                      active: !_isBuying,
                      onTap: () =>
                          setState(() => _isBuying = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Shares / Amount toggle
              Row(
                children: [
                  Text('Enter by', style: AppTextStyles.caption),
                  const SizedBox(width: 10),
                  _ModeChip(
                    label: 'Shares',
                    active: !_isAmountMode,
                    onTap: () {
                      setState(() => _isAmountMode = false);
                      _inputCtrl.clear();
                    },
                  ),
                  const SizedBox(width: 6),
                  _ModeChip(
                    label: 'Amount (\$)',
                    active: _isAmountMode,
                    onTap: () {
                      setState(() => _isAmountMode = true);
                      _inputCtrl.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Input field
              Text(
                _isAmountMode ? 'Dollar amount' : 'Number of shares',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  // Allow digits + one dot + up to 5dp (shares) or 2dp (amount)
                  FilteringTextInputFormatter.allow(
                      _isAmountMode
                          ? RegExp(r'^\d*\.?\d{0,2}')
                          : RegExp(r'^\d*\.?\d{0,5}')),
                ],
                style: AppTextStyles.priceLarge.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
                onChanged: (_) => _validate(),
                textInputAction: TextInputAction.done,
                onEditingComplete: () =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  hintText: _isAmountMode ? '0.00' : '0.00000',
                  hintStyle: AppTextStyles.priceLarge.copyWith(
                      fontSize: 26, color: AppColors.borderGrey),
                  prefixText: _isAmountMode ? '\$  ' : null,
                  prefixStyle: AppTextStyles.label
                      .copyWith(color: AppColors.mediumGrey),
                  errorText: _inputError,
                  errorStyle: AppTextStyles.errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.borderGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.gold, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.dangerRed, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.dangerRed, width: 1.5),
                  ),
                  // Done button inside field for number keyboards
                  suffixIcon: GestureDetector(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Done',
                          style: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),

              // Quick percentage buttons (buy = % of cash, sell = % of holding)
              if (_isBuying || holding != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: ['10%', '25%', '50%', 'Max'].map((label) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          double pct;
                          switch (label) {
                            case '10%':
                              pct = 0.10;
                              break;
                            case '25%':
                              pct = 0.25;
                              break;
                            case '50%':
                              pct = 0.50;
                              break;
                            default:
                              pct = 1.0;
                          }
                          _applyPercentage(pct);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.darkGold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Summary card
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
                    if (_isAmountMode)
                      _SummaryRow(
                        label: 'Shares you will get',
                        value: AppFormatters.shares(_shares),
                        bold: true,
                      )
                    else
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
      ),
    );
  }
}

// ── Chart ──────────────────────────────────────────────────────────────────────
class _PriceChart extends StatelessWidget {
  final Asset asset;
  const _PriceChart({required this.asset});

  @override
  Widget build(BuildContext context) {
    if (asset.priceHistory.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
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
    final lineColor =
        asset.isUp ? AppColors.successGreen : AppColors.dangerRed;

    return SizedBox(
      height: 160,
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
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.18),
                    lineColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        AppFormatters.price(s.y),
                        AppTextStyles.captionBold
                            .copyWith(color: Colors.white),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────
class _ToggleOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleOption(
      {required this.label, required this.active, required this.onTap});

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
                color: active ? Colors.white : const Color(0xFF444444),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: active ? Colors.white : const Color(0xFF444444),
            fontWeight: FontWeight.w600,
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

  const _SummaryRow(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: bold
                ? AppTextStyles.label
                : AppTextStyles.bodyMedium),
        Text(value,
            style: bold
                ? AppTextStyles.label
                    .copyWith(color: AppColors.nearBlack)
                : AppTextStyles.bodyMedium),
      ],
    );
  }
}
