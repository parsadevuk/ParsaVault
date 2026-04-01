import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/news_service.dart';
import '../models/news_article.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final newsServiceProvider = Provider<NewsService>((ref) => NewsService());

// ── State ─────────────────────────────────────────────────────────────────────

class NewsState {
  final List<NewsArticle> visible; // slice shown in UI right now
  final int total; // total after filtering
  final bool hasMore;
  final bool isLoadingMore;
  final NewsCategory? filter; // null = All
  final NewsSortOrder sort;

  const NewsState({
    required this.visible,
    required this.total,
    required this.hasMore,
    this.isLoadingMore = false,
    this.filter,
    this.sort = NewsSortOrder.latest,
  });

  NewsState copyWith({
    List<NewsArticle>? visible,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
    NewsCategory? Function()? filter,
    NewsSortOrder? sort,
  }) {
    return NewsState(
      visible: visible ?? this.visible,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filter: filter != null ? filter() : this.filter,
      sort: sort ?? this.sort,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NewsNotifier extends AsyncNotifier<NewsState> {
  static const int _pageSize = 20;

  List<NewsArticle> _master = []; // all articles from all feeds
  NewsCategory? _filterCategory;
  NewsSortOrder _sort = NewsSortOrder.latest;
  int _visibleCount = _pageSize;

  @override
  Future<NewsState> build() async {
    _master = await ref.read(newsServiceProvider).fetchAll();
    return _buildState();
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Reveal the next 20 articles (no network call — already in memory).
  void loadMore() {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    // Brief loading indicator
    state = AsyncData(current.copyWith(isLoadingMore: true));
    _visibleCount += _pageSize;
    state = AsyncData(_buildState());
  }

  void setFilter(NewsCategory? category) {
    _filterCategory = category;
    _visibleCount = _pageSize; // reset to first page on filter change
    state = AsyncData(_buildState());
  }

  void setSort(NewsSortOrder sort) {
    _sort = sort;
    _visibleCount = _pageSize;
    state = AsyncData(_buildState());
  }

  Future<void> refresh() async {
    _visibleCount = _pageSize;
    state = const AsyncLoading();
    try {
      _master = await ref.read(newsServiceProvider).fetchAll();
      state = AsyncData(_buildState());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  NewsState _buildState() {
    // Apply filter
    List<NewsArticle> filtered = _filterCategory == null
        ? List.of(_master)
        : _master.where((a) => a.category == _filterCategory).toList();

    // Apply sort
    if (_sort == NewsSortOrder.oldest) {
      filtered.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
    }
    // latest is default (already sorted by fetchAll)

    final total = filtered.length;
    final visible = filtered.take(_visibleCount).toList();

    return NewsState(
      visible: visible,
      total: total,
      hasMore: _visibleCount < total,
      filter: _filterCategory,
      sort: _sort,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final newsProvider =
    AsyncNotifierProvider<NewsNotifier, NewsState>(NewsNotifier.new);
