import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_transaction.dart';
import '../../providers/history_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/transaction_tile.dart';
import '../../widgets/common/empty_state.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      final state = ref.read(historyProvider);
      if (state.hasMore && !state.isLoadingMore && !state.isLoading) {
        ref.read(historyProvider.notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);
    final filtered = state.filtered;

    // Group by date
    final Map<String, List<AppTransaction>> grouped = {};
    for (final tx in filtered) {
      final key = AppFormatters.date(tx.timestamp);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('Transaction History', style: AppTextStyles.screenTitle),
            ),

            // ── Filter pills ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: ['All', 'Buys', 'Sells', 'Deposits', 'Withdrawals']
                      .map((label) {
                    final active = state.filter == label;
                    return GestureDetector(
                      onTap: () =>
                          ref.read(historyProvider.notifier).setFilter(label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? AppColors.gold : AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: AppTextStyles.caption.copyWith(
                            color: active ? Colors.white : const Color(0xFF555555),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.gold,
                      onRefresh: () =>
                          ref.read(historyProvider.notifier).refresh(),
                      child: filtered.isEmpty
                          ? ListView(
                              controller: _scrollController,
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.55,
                                  child: EmptyState(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'No trades yet.',
                                    body:
                                        'Make your first trade and it\'ll show up here.',
                                    buttonLabel: 'Go to Markets',
                                    onButtonTap: () {
                                      ref
                                          .read(navigationIndexProvider.notifier)
                                          .state = 1;
                                    },
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(top: 8),
                              itemCount: _itemCount(grouped, state),
                              itemBuilder: (context, index) =>
                                  _buildItem(context, index, grouped, state),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Build flat index list: date-header → tiles → (optional) load-more footer
  int _itemCount(
    Map<String, List<AppTransaction>> grouped,
    HistoryState state,
  ) {
    // Each group = 1 header + N tiles
    int count = grouped.entries
        .fold(0, (sum, e) => sum + 1 + e.value.length);
    count += 1; // footer (spinner or end label)
    return count;
  }

  Widget? _buildItem(
    BuildContext context,
    int index,
    Map<String, List<AppTransaction>> grouped,
    HistoryState state,
  ) {
    // Flatten grouped map into a list of items
    final flatItems = <_HistoryItem>[];
    for (final entry in grouped.entries) {
      flatItems.add(_HistoryItem.header(entry.key));
      for (final tx in entry.value) {
        flatItems.add(_HistoryItem.tile(tx));
      }
    }

    // Footer is the last item
    if (index == flatItems.length) {
      return _buildFooter(context, state);
    }

    final item = flatItems[index];
    if (item.isHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Text(
          item.header!,
          style: AppTextStyles.captionBold.copyWith(fontSize: 13),
        ),
      );
    }

    return Column(
      children: [
        TransactionTile(tx: item.tx!),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, HistoryState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Center(
          child: Text(
            'All transactions loaded',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.mediumGrey,
            ),
          ),
        ),
      );
    }
    return SizedBox(height: MediaQuery.of(context).padding.bottom + 24);
  }
}

// ── Helper ─────────────────────────────────────────────────────────────────────

class _HistoryItem {
  final String? header;
  final AppTransaction? tx;

  const _HistoryItem._({this.header, this.tx});

  factory _HistoryItem.header(String label) =>
      _HistoryItem._(header: label);
  factory _HistoryItem.tile(AppTransaction tx) =>
      _HistoryItem._(tx: tx);

  bool get isHeader => header != null;
}
