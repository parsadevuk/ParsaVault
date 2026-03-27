import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

class ParsaVaultApp extends StatelessWidget {
  const ParsaVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parsa Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
