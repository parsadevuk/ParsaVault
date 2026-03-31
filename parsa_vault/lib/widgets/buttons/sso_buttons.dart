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

/// A row of SSO icon-only square buttons.
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
        _SsoSquareButton(
          onPressed: onApple,
          backgroundColor: AppColors.nearBlack,
          border: null,
          icon: const Icon(Icons.apple, color: Colors.white, size: 26),
        ),
      _SsoSquareButton(
        onPressed: onGoogle,
        backgroundColor: AppColors.white,
        border: Border.all(color: AppColors.borderGrey, width: 1.5),
        icon: const _GoogleGIcon(),
      ),
      _SsoSquareButton(
        onPressed: onMicrosoft,
        backgroundColor: AppColors.white,
        border: Border.all(color: AppColors.borderGrey, width: 1.5),
        icon: const _MicrosoftIcon(),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          buttons[i],
        ],
      ],
    );
  }
}

// ── Square button shell ─────────────────────────────────────────────────────

class _SsoSquareButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final BoxBorder? border;
  final Widget icon;

  const _SsoSquareButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.border,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Opacity(
            opacity: onPressed == null ? 0.45 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: border,
              ),
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Icons ───────────────────────────────────────────────────────────────────

class _GoogleGIcon extends StatelessWidget {
  const _GoogleGIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

class _MicrosoftIcon extends StatelessWidget {
  const _MicrosoftIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          ColoredBox(color: Color(0xFFF25022)), // red
          ColoredBox(color: Color(0xFF7FBA00)), // green
          ColoredBox(color: Color(0xFF00A4EF)), // blue
          ColoredBox(color: Color(0xFFFFB900)), // yellow
        ],
      ),
    );
  }
}
