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

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppleSignInButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _SsoButton(
      onPressed: onPressed,
      backgroundColor: AppColors.nearBlack,
      border: null,
      icon: const Icon(Icons.apple, color: Colors.white, size: 22),
      label: Text(
        'Sign in with Apple',
        style: AppTextStyles.buttonText.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleSignInButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _SsoButton(
      onPressed: onPressed,
      backgroundColor: AppColors.white,
      border: Border.all(color: AppColors.borderGrey, width: 1.5),
      icon: const _GoogleGIcon(),
      label: Text(
        'Continue with Google',
        style: AppTextStyles.buttonText.copyWith(
          color: AppColors.nearBlack,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class MicrosoftSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const MicrosoftSignInButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _SsoButton(
      onPressed: onPressed,
      backgroundColor: AppColors.white,
      border: Border.all(color: AppColors.borderGrey, width: 1.5),
      icon: const _MicrosoftIcon(),
      label: Text(
        'Continue with Microsoft',
        style: AppTextStyles.buttonText.copyWith(
          color: AppColors.nearBlack,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Shared button shell ────────────────────────────────────────────────────────
class _SsoButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final BoxBorder? border;
  final Widget icon;
  final Widget label;

  const _SsoButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.border,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: onPressed == null ? 0.45 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: border,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  label,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Icons ──────────────────────────────────────────────────────────────────────
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
            fontSize: 18,
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
