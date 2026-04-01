import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/welcome_screen.dart';
import '../main/main_navigation.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _barController;

  late Animation<double> _logoFade;
  late Animation<double> _barProgress;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _barController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));

    _logoFade =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _barProgress =
        CurvedAnimation(parent: _barController, curve: Curves.easeInOut);
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
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
        destination = const WelcomeScreen();
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
    _fadeController.dispose();
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
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen loading screen image with fade-in
          FadeTransition(
            opacity: _logoFade,
            child: Image.asset(
              'assets/images/splash_screen.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
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
                backgroundColor: Colors.white12,
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
