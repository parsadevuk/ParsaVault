import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../models/app_transaction.dart';
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
  String _filter = 'All';

  List<AppTransaction> _filtered(List<AppTransaction> txs) {
    switch (_filter) {
      case 'Buys':
        return txs.where((t) => t.isBuy).toList();
      case 'Sells':
        return txs.where((t) => t.isSell).toList();
      default:
        return txs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);
    final filtered = _filtered(portfolio.transactions);

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
              child:
                  Text('Transaction History', style: AppTextStyles.screenTitle),
            ),

            // Filter pills
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: ['All', 'Buys', 'Sells'].map((label) {
                  final active = _filter == label;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = label),
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
                          color: active ? Colors.white : AppColors.mediumGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No trades yet.',
                      body:
                          'Make your first trade and it\'ll show up here.',
                      buttonLabel: 'Go to Markets',
                      onButtonTap: () {
                        ref.read(navigationIndexProvider.notifier).state = 1;
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      children: [
                        for (final entry in grouped.entries) ...[
                          // Date header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                            child: Text(
                              entry.key,
                              style: AppTextStyles.captionBold
                                  .copyWith(fontSize: 13),
                            ),
                          ),
                          for (final tx in entry.value) ...[
                            TransactionTile(tx: tx),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
