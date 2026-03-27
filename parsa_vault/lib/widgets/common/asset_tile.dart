import 'package:flutter/material.dart';
import '../../models/asset.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';

class AssetTile extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;
  final double? sharesOwned;

  const AssetTile({
    super.key,
    required this.asset,
    this.onTap,
    this.sharesOwned,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = asset.isUp;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Icon circle
            _AssetIcon(symbol: asset.symbol, isStock: asset.isStock),
            const SizedBox(width: 12),
            // Name + symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.symbol,
                    style: AppTextStyles.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    asset.name,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sharesOwned != null && sharesOwned! > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${AppFormatters.shares(sharesOwned!)} shares',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Price + change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.price(asset.currentPrice),
                  style: AppTextStyles.priceSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.percentage(asset.changePercent24h),
                  style: isUp
                      ? AppTextStyles.percentageUp
                      : AppTextStyles.percentageDown,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetIcon extends StatelessWidget {
  final String symbol;
  final bool isStock;

  const _AssetIcon({required this.symbol, required this.isStock});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isStock
            ? AppColors.lightGrey
            : AppColors.goldLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isStock
            ? Icon(Icons.show_chart, size: 22, color: AppColors.nearBlack)
            : Icon(Icons.currency_bitcoin, size: 22, color: AppColors.gold),
      ),
    );
  }
}
