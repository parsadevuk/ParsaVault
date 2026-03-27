import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/xp_calculator.dart';

class XpProgressBar extends StatelessWidget {
  final int xp;
  final int level;

  const XpProgressBar({super.key, required this.xp, required this.level});

  @override
  Widget build(BuildContext context) {
    final progress = XpCalculator.getXpProgress(xp);
    final title = XpCalculator.getLevelTitle(level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Level $level · $title', style: AppTextStyles.levelText),
            Text(
              '${progress.current} / ${progress.required} XP',
              style: AppTextStyles.xpText,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.percentage),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.borderGrey,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.gold),
              );
            },
          ),
        ),
      ],
    );
  }
}
