import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/trade_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParsaVaultApp());
}

class ParsaVaultApp extends StatelessWidget {
  const ParsaVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parsa Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
          case '/onboarding':
            return MaterialPageRoute(
              builder: (_) => const OnboardingScreen(),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (_) => const RegisterScreen(),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          case '/main':
            return MaterialPageRoute(
              builder: (_) => const MainScreen(),
            );
          case '/trade-detail':
            final asset = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => TradeDetailScreen(asset: asset),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
        }
      },
    );
  }
}
