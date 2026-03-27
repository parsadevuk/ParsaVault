import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LevelBadge extends StatelessWidget {
  final int level;
  final bool compact;

  const LevelBadge({super.key, required this.level, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'LVL $level',
        style: AppTextStyles.badgeText.copyWith(
          fontSize: compact ? 10 : 11,
        ),
      ),
    );
  }
}
