import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asset.dart';
import '../data/services/market_service.dart';
import '../utils/constants.dart';

// ── State ──────────────────────────────────────────────────────────────────────
class MarketState {
  final List<Asset> stocks;
  final List<Asset> cryptos;
  final bool isLoading;
  final DateTime? lastUpdated;

  const MarketState({
    this.stocks = const [],
    this.cryptos = const [],
    this.isLoading = true,
    this.lastUpdated,
  });

  List<Asset> get all => [...stocks, ...cryptos];

  Asset? findBySymbol(String symbol) {
    try {
      return all.firstWhere((a) => a.symbol == symbol);
    } catch (_) {
      return null;
    }
  }

  MarketState copyWith({
    List<Asset>? stocks,
    List<Asset>? cryptos,
    bool? isLoading,
    DateTime? lastUpdated,
  }) {
    return MarketState(
      stocks: stocks ?? this.stocks,
      cryptos: cryptos ?? this.cryptos,
      isLoading: isLoading ?? this.isLoading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────
class MarketNotifier extends StateNotifier<MarketState> {
  final MarketService _service = MarketService();
  Timer? _timer;

  MarketNotifier() : super(const MarketState()) {
    _init();
  }

  void _init() {
    final assets = _service.generateAssets();
    final stocks = assets.where((a) => a.isStock).toList();
    final cryptos = assets.where((a) => a.isCrypto).toList();
    state = MarketState(
      stocks: stocks,
      cryptos: cryptos,
      isLoading: false,
      lastUpdated: DateTime.now(),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: AppConstants.priceUpdateIntervalSeconds),
      (_) => _tickPrices(),
    );
  }

  void _tickPrices() {
    if (!mounted) return;
    final updatedStocks = state.stocks.map(_service.tickPrice).toList();
    final updatedCryptos = state.cryptos.map(_service.tickPrice).toList();
    state = state.copyWith(
      stocks: updatedStocks,
      cryptos: updatedCryptos,
      lastUpdated: DateTime.now(),
    );
  }

  void refresh() => _tickPrices();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  return MarketNotifier();
});
