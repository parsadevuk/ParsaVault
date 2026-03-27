import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import '../main/main_navigation.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _nameController;
  late AnimationController _taglineController;
  late AnimationController _barController;

  late Animation<double> _logoFade;
  late Animation<double> _nameFade;
  late Animation<double> _taglineFade;
  late Animation<double> _barProgress;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _nameController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _taglineController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _barController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));

    _logoFade =
        CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _nameFade =
        CurvedAnimation(parent: _nameController, curve: Curves.easeOut);
    _taglineFade =
        CurvedAnimation(parent: _taglineController, curve: Curves.easeOut);
    _barProgress =
        CurvedAnimation(parent: _barController, curve: Curves.easeInOut);
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _nameController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _taglineController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _barController.forward();

    // Wait for bar to finish then route
    await Future.delayed(const Duration(milliseconds: 3000));
    _route();
  }

  void _route() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final authState = ref.read(authProvider);
    Widget destination;

    switch (authState.status) {
      case AuthStatus.authenticated:
        destination = const MainNavigation();
        break;
      case AuthStatus.unauthenticated:
        destination = const LoginScreen();
        break;
      case AuthStatus.noUsers:
        destination = const OnboardingScreen();
        break;
      case AuthStatus.checking:
        // Still checking — listen for the change
        ref.listenManual(authProvider, (_, next) {
          if (!_navigated && next.status != AuthStatus.checking) {
            _route();
          }
        });
        return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _nameController.dispose();
    _taglineController.dispose();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth check completing while we are on splash
    ref.listen(authProvider, (prev, next) {
      if (next.status != AuthStatus.checking) {
        _route();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Centred logo + text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo placeholder (gold P in a circle)
                FadeTransition(
                  opacity: _logoFade,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        'P',
                        style: AppTextStyles.displayHeadline.copyWith(
                          fontSize: 56,
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _nameFade,
                  child: Text('Parsa Vault', style: AppTextStyles.displayHeadline),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'Secure your wealth. Master the markets.',
                    style: AppTextStyles.tagline,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Gold loading bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _barProgress,
              builder: (_, __) => LinearProgressIndicator(
                value: _barProgress.value,
                minHeight: 4,
                backgroundColor: AppColors.borderGrey,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
