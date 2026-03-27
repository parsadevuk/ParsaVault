import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class DestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const DestructiveButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dangerRed,
          side: const BorderSide(color: AppColors.dangerRed, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(color: AppColors.dangerRed),
        ),
      ),
    );
  }
}
