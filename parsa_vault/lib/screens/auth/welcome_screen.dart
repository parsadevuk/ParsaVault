import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Force light status bar icons (white) over the dark image
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      body: Stack(
        children: [
          // ── Background image, focal point top-right ──────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_bg.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.65, -0.8),
            ),
          ),

          // ── Gradient overlay: clear at top → deep dark at bottom ─────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.82),
                    Colors.black.withValues(alpha: 0.94),
                  ],
                  stops: const [0.0, 0.38, 0.72, 1.0],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 5),

                  // App logo
                  Image.asset(
                    'assets/images/logo_transparent_full.png',
                    width: 320,
                    height: 320,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),

                  // App name
                  Text(
                    'PARSA VAULT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Gold accent divider
                  Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tagline
                  Text(
                    'Secure your wealth.\nMaster the markets.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Create Account — outline ghost button
                  _WelcomeButton(
                    label: 'Create Account',
                    filled: false,
                    onTap: () => Navigator.of(context).push(
                      _slide(const RegisterScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Log In — gold filled button
                  _WelcomeButton(
                    label: 'Log In',
                    filled: true,
                    onTap: () => Navigator.of(context).push(
                      _slide(const LoginScreen()),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      );
}

// ── Reusable welcome button ────────────────────────────────────────────────────

class _WelcomeButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _WelcomeButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: filled ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: filled ? AppColors.gold : Colors.white.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: filled ? AppColors.nearBlack : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
