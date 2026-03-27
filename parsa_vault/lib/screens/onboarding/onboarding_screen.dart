import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons/gold_button.dart';
import '../auth/register_screen.dart';

class _Slide {
  final IconData icon;
  final String headline;
  final String body;

  const _Slide(this.icon, this.headline, this.body);
}

const _slides = [
  _Slide(
    Icons.lock_outlined,
    'Welcome to Parsa Vault',
    'Trade stocks and crypto with \$10,000 virtual cash. No risk, all the thrill.',
  ),
  _Slide(
    Icons.trending_up_rounded,
    'Real prices. Zero risk.',
    'Live market data from real exchanges. Buy and sell just like a real trader would.',
  ),
  _Slide(
    Icons.refresh_rounded,
    'Fail. Reset. Learn. Repeat.',
    'Lost all your money? No problem. Reset, start with \$10,000 again, and come back stronger.',
  ),
  _Slide(
    Icons.star_outline_rounded,
    'The more you trade, the more you grow.',
    'Earn XP with every trade. Level up your account and see how far you can go.',
  ),
  _Slide(
    Icons.check_circle_outline_rounded,
    'Your vault is ready.',
    'Create your account and start with \$10,000. Your path to mastering the markets starts now.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToRegister();
    }
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 24),
                child: TextButton(
                  onPressed: _goToRegister,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.label.copyWith(color: AppColors.gold),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
              ),
            ),

            // Dot indicator
            _DotIndicator(count: _slides.length, current: _currentPage),
            const SizedBox(height: 24),

            // Next / Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GoldButton(
                label: _currentPage == _slides.length - 1
                    ? 'Get Started'
                    : 'Next',
                onPressed: _nextPage,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),
          // Illustration area
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 64, color: AppColors.gold),
          ),
          const SizedBox(height: 40),
          Text(
            slide.headline,
            style: AppTextStyles.screenTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.mediumGrey),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.gold : AppColors.borderGrey,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
