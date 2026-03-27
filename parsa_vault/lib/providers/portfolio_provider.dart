import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/holding.dart';
import '../models/app_transaction.dart';
import '../data/services/portfolio_service.dart';
import 'auth_provider.dart';
import 'market_provider.dart';

// ── State ──────────────────────────────────────────────────────────────────────
class PortfolioState {
  final List<Holding> holdings;
  final List<AppTransaction> transactions;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const PortfolioState({
    this.holdings = const [],
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  PortfolioState copyWith({
    List<Holding>? holdings,
    List<AppTransaction>? transactions,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PortfolioState(
      holdings: holdings ?? this.holdings,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────
class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final Ref _ref;
  final PortfolioService _service = PortfolioService();

  PortfolioNotifier(this._ref) : super(const PortfolioState());

  String? get _userId => _ref.read(authProvider).user?.id;

  Future<void> loadAll() async {
    final uid = _userId;
    if (uid == null) return;
    state = state.copyWith(isLoading: true);
    final holdings = await _service.getHoldings(uid);
    final transactions = await _service.getTransactions(uid);
    state = state.copyWith(
      holdings: holdings,
      transactions: transactions,
      isLoading: false,
    );
  }

  double getPortfolioValue() {
    final user = _ref.read(authProvider).user;
    if (user == null) return 0;
    final market = _ref.read(marketProvider);
    double holdingsValue = 0;
    for (final h in state.holdings) {
      final asset = market.findBySymbol(h.symbol);
      final price = asset?.currentPrice ?? h.averageBuyPrice;
      holdingsValue += h.shares * price;
    }
    return user.cashBalance + holdingsValue;
  }

  double getHoldingsValue() {
    final market = _ref.read(marketProvider);
    double total = 0;
    for (final h in state.holdings) {
      final asset = market.findBySymbol(h.symbol);
      final price = asset?.currentPrice ?? h.averageBuyPrice;
      total += h.shares * price;
    }
    return total;
  }

  Future<bool> buy({
    required String symbol,
    required String assetName,
    required String assetType,
    required double shares,
    required double currentPrice,
  }) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return false;

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _service.buy(
      user: user,
      symbol: symbol,
      assetName: assetName,
      assetType: assetType,
      shares: shares,
      currentPrice: currentPrice,
    );

    if (result.success) {
      await _ref.read(authProvider.notifier).refreshUser();
      await loadAll();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Trade done. +${result.xpAwarded} XP earned.',
      );
      return true;
    }

    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  Future<bool> sell({
    required String symbol,
    required String assetName,
    required String assetType,
    required double shares,
    required double currentPrice,
  }) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return false;

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final result = await _service.sell(
      user: user,
      symbol: symbol,
      assetName: assetName,
      assetType: assetType,
      shares: shares,
      currentPrice: currentPrice,
    );

    if (result.success) {
      await _ref.read(authProvider.notifier).refreshUser();
      await loadAll();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Trade done. +${result.xpAwarded} XP earned.',
      );
      return true;
    }

    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  Future<bool> deposit(double amount) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.deposit(user: user, amount: amount);

    if (result.success) {
      await _ref.read(authProvider.notifier).refreshUser();
      await loadAll();
      state = state.copyWith(isLoading: false, successMessage: 'Deposited. Your cash balance is updated.');
      return true;
    }

    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  Future<bool> withdraw(double amount) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _service.withdraw(user: user, amount: amount);

    if (result.success) {
      await _ref.read(authProvider.notifier).refreshUser();
      await loadAll();
      state = state.copyWith(isLoading: false, successMessage: 'Done. Cash withdrawn.');
      return true;
    }

    state = state.copyWith(isLoading: false, error: result.error);
    return false;
  }

  Future<void> resetPortfolio() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    state = state.copyWith(isLoading: true);
    await _service.resetPortfolio(user);
    await _ref.read(authProvider.notifier).refreshUser();
    await loadAll();
  }

  Future<void> resetAll() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    state = state.copyWith(isLoading: true);
    await _service.resetAll(user);
    await _ref.read(authProvider.notifier).refreshUser();
    await loadAll();
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  final notifier = PortfolioNotifier(ref);
  // Load holdings when auth changes to authenticated
  ref.listen(authProvider, (prev, next) {
    if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
      notifier.loadAll();
    }
  });
  return notifier;
});
