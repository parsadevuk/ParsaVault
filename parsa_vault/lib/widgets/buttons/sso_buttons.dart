import 'dart:io';

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SsoDivider extends StatelessWidget {
  const SsoDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.borderGrey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'or continue with',
              style: AppTextStyles.caption.copyWith(fontSize: 12),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.borderGrey)),
        ],
      ),
    );
  }
}

/// A row of SSO image buttons using custom PNG assets.
/// Apple is shown on iOS only.
class SsoIconRow extends StatelessWidget {
  final VoidCallback? onApple;
  final VoidCallback? onGoogle;
  final VoidCallback? onMicrosoft;

  const SsoIconRow({
    super.key,
    this.onApple,
    this.onGoogle,
    this.onMicrosoft,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (Platform.isIOS)
        _SsoImageButton(
          onPressed: onApple,
          assetPath: 'assets/images/sso_apple.png',
        ),
      _SsoImageButton(
        onPressed: onGoogle,
        assetPath: 'assets/images/sso_google.png',
      ),
      _SsoImageButton(
        onPressed: onMicrosoft,
        assetPath: 'assets/images/sso_microsoft.png',
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 20),
          buttons[i],
        ],
      ],
    );
  }
}

// ── Image button ─────────────────────────────────────────────────────────────

class _SsoImageButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String assetPath;

  const _SsoImageButton({
    required this.onPressed,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: onPressed,
        child: Image.asset(
          assetPath,
          width: 58,
          height: 58,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
