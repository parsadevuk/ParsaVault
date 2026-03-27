import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/home_screen.dart';
import '../markets/markets_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../leaderboard/leaderboard_screen.dart';

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex == 2 ? 1 : currentIndex,
        children: const [
          HomeScreen(),
          MarketsScreen(),
          HistoryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _ParsaBottomNav(
        currentIndex: currentIndex,
        onTap: (i) =>
            ref.read(navigationIndexProvider.notifier).state = i,
      ),
    );
  }
}

class _ParsaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ParsaBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.borderGrey, width: 1)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Markets',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              // Centre trade button
              _CentreTradeButton(
                isActive: currentIndex == 2,
                onTap: () => onTap(1), // opens markets to select asset
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'History',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? AppColors.gold : AppColors.mediumGrey,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.tabLabel.copyWith(
                color: isActive ? AppColors.gold : AppColors.mediumGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CentreTradeButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _CentreTradeButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Trade',
              style: AppTextStyles.tabLabel.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper to navigate to leaderboard from anywhere
class LeaderboardNavHelper {
  static void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }
}
