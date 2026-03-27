import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/gold_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppColors.gold),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: AppTextStyles.sectionHeading,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.mediumGrey),
                textAlign: TextAlign.center),
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: 24),
              GoldButton(label: buttonLabel!, onPressed: onButtonTap),
            ],
          ],
        ),
      ),
    );
  }
}
