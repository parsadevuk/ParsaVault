import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/transaction_repository.dart';
import '../models/app_transaction.dart';
import 'auth_provider.dart';

const _kPageSize = 40;

// ── State ─────────────────────────────────────────────────────────────────────

class HistoryState {
  final List<AppTransaction> items; // all fetched from Firestore so far
  final DocumentSnapshot? cursor;   // Firestore cursor for next page
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String filter;

  const HistoryState({
    this.items = const [],
    this.cursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.filter = 'All',
  });

  /// Items after the active filter is applied.
  List<AppTransaction> get filtered {
    switch (filter) {
      case 'Buys':
        return items.where((t) => t.isBuy).toList();
      case 'Sells':
        return items.where((t) => t.isSell).toList();
      case 'Deposits':
        return items.where((t) => t.isDeposit).toList();
      case 'Withdrawals':
        return items.where((t) => t.isWithdraw).toList();
      default:
        return items;
    }
  }

  HistoryState copyWith({
    List<AppTransaction>? items,
    DocumentSnapshot? cursor,
    bool clearCursor = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? filter,
  }) {
    return HistoryState(
      items: items ?? this.items,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;
  final _repo = TransactionRepository();

  HistoryNotifier(this._ref) : super(const HistoryState()) {
    // Load when auth is ready.
    if (_ref.read(authProvider).isAuthenticated) {
      Future.microtask(_initialLoad);
    }
    _ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        _initialLoad();
      }
      if (!next.isAuthenticated) {
        state = const HistoryState();
      }
    });
  }

  String? get _uid => _ref.read(authProvider).user?.id;

  Future<void> _initialLoad() async {
    final uid = _uid;
    if (uid == null) return;
    state = state.copyWith(isLoading: true, items: [], clearCursor: true, hasMore: true);
    final result = await _repo.findPaged(uid, limit: _kPageSize);
    state = state.copyWith(
      items: result.items,
      cursor: result.cursor,
      isLoading: false,
      hasMore: result.items.length >= _kPageSize,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    final uid = _uid;
    if (uid == null) return;
    state = state.copyWith(isLoadingMore: true);
    final result = await _repo.findPaged(uid, limit: _kPageSize, after: state.cursor);
    state = state.copyWith(
      items: [...state.items, ...result.items],
      cursor: result.cursor ?? state.cursor,
      isLoadingMore: false,
      hasMore: result.items.length >= _kPageSize,
    );
  }

  Future<void> refresh() => _initialLoad();

  void setFilter(String filter) => state = state.copyWith(filter: filter);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});
