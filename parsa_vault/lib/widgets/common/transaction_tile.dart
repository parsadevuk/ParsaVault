import 'package:flutter/material.dart';
import '../../models/app_transaction.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final AppTransaction tx;

  const TransactionTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    Color accentColor = tx.isBuy
        ? AppColors.successGreen
        : tx.isSell
            ? AppColors.dangerRed
            : AppColors.gold;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (tx.symbol != null)
                        Text(tx.symbol!, style: AppTextStyles.label),
                      if (tx.symbol != null) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tx.typeLabel,
                          style: AppTextStyles.captionBold.copyWith(
                            color: accentColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (tx.isTrade && tx.shares != null && tx.priceAtTime != null)
                    Text(
                      '${AppFormatters.shares(tx.shares!)} shares at ${AppFormatters.price(tx.priceAtTime!)}',
                      style: AppTextStyles.caption,
                    )
                  else
                    Text(
                      tx.isDeposit ? 'Cash added' : 'Cash withdrawn',
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (tx.isSell || tx.isDeposit ? '+' : '-') +
                      AppFormatters.currency(tx.totalAmount),
                  style: AppTextStyles.priceSmall.copyWith(
                    color:
                        tx.isSell || tx.isDeposit ? AppColors.successGreen : AppColors.nearBlack,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppFormatters.time(tx.timestamp),
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
                if (tx.xpAwarded > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+${tx.xpAwarded} XP',
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.gold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
