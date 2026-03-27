import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../buttons/destructive_button.dart';

Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String confirmLabel,
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.overlay,
    builder: (ctx) => _ConfirmationDialog(
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    ),
  );
  return result ?? false;
}

class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final bool isDestructive;

  const _ConfirmationDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.sectionHeading),
            const SizedBox(height: 12),
            Text(body,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.mediumGrey)),
            const SizedBox(height: 24),
            if (isDestructive)
              DestructiveButton(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.mediumGrey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
