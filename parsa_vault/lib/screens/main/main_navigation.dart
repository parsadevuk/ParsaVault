import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import '../markets/markets_screen.dart';
import '../news/news_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../leaderboard/leaderboard_screen.dart';

// Nav:   0=Home  1=Markets  2=News  3=History  4=Profile
// Stack: 0=Home  1=MarketsNewsCarousel           2=History  3=Profile
int _toStackIndex(int navIndex) {
  if (navIndex == 0) return 0;
  if (navIndex <= 2) return 1; // Markets or News → carousel
  return navIndex - 1;         // History(3→2), Profile(4→3)
}

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(
        index: _toStackIndex(currentIndex),
        children: const [
          HomeScreen(),
          _MarketsNewsCarousel(),
          HistoryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CurvedNavigationBar(
          index: currentIndex,
          height: 57,
          color: AppColors.white,
          buttonBackgroundColor: AppColors.gold,
          backgroundColor: AppColors.white,
          animationDuration: const Duration(milliseconds: 300),
          animationCurve: Curves.easeInOut,
          onTap: (index) =>
              ref.read(navigationIndexProvider.notifier).state = index,
          items: [
            _navIcon(Icons.home_rounded,         0, currentIndex),
            _navIcon(Icons.candlestick_chart,    1, currentIndex),
            _navIcon(Icons.newspaper_rounded,    2, currentIndex),
            _navIcon(Icons.receipt_long_rounded, 3, currentIndex),
            _navIcon(Icons.person_rounded,       4, currentIndex),
          ],
        ),
      ),
    );
  }

  static Icon _navIcon(IconData icon, int index, int currentIndex) {
    final isActive = currentIndex == index;
    return Icon(
      icon,
      size: isActive ? 31 : 26,
      color: AppColors.nearBlack,
    );
  }
}

// ── Markets ↔ News swipeable carousel ─────────────────────────────────────────

class _MarketsNewsCarousel extends ConsumerStatefulWidget {
  const _MarketsNewsCarousel();

  @override
  ConsumerState<_MarketsNewsCarousel> createState() =>
      _MarketsNewsCarouselState();
}

class _MarketsNewsCarouselState extends ConsumerState<_MarketsNewsCarousel> {
  late final PageController _pc;

  @override
  void initState() {
    super.initState();
    final navIndex = ref.read(navigationIndexProvider);
    _pc = PageController(initialPage: navIndex == 2 ? 1 : 0);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sync page controller when nav bar is tapped
    ref.listen(navigationIndexProvider, (_, next) {
      if ((next == 1 || next == 2) && _pc.hasClients) {
        final target = next == 2 ? 1 : 0;
        if (_pc.page?.round() != target) {
          _pc.animateToPage(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    return PageView(
      controller: _pc,
      onPageChanged: (page) {
        // Sync nav bar when user swipes
        ref.read(navigationIndexProvider.notifier).state =
            page == 0 ? 1 : 2;
      },
      children: const [
        MarketsScreen(),
        NewsScreen(),
      ],
    );
  }
}

// ── Leaderboard helper ────────────────────────────────────────────────────────

class LeaderboardNavHelper {
  static void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }
}
