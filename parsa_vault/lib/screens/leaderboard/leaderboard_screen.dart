import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/xp_calculator.dart';
import '../../widgets/common/level_badge.dart';

class _LeaderboardEntry {
  final String username;
  final String initials;
  final int xp;
  final bool isCurrentUser;

  const _LeaderboardEntry({
    required this.username,
    required this.initials,
    required this.xp,
    required this.isCurrentUser,
  });
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _todayUtc {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  DateTime get _weekStartUtc {
    final today = _todayUtc;
    final daysFromMonday = today.weekday - 1;
    return today.subtract(Duration(days: daysFromMonday));
  }

  String _periodLabel(String period) {
    if (period == 'weekly') {
      final start = _weekStartUtc;
      return 'Week of ${start.day}/${start.month} (UTC)';
    }
    if (period == 'daily') {
      final now = _todayUtc;
      return '${now.day}/${now.month}/${now.year} (UTC)';
    }
    return 'All Time';
  }

  List<_LeaderboardEntry> _toEntries(List<User> users, String currentUserId) {
    return users.map((u) => _LeaderboardEntry(
          username: u.username,
          initials: u.initials,
          xp: u.xp,
          isCurrentUser: u.id == currentUserId,
        )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasNav = Navigator.of(context).canPop();
    final currentUser = ref.watch(authProvider).user;
    final leaderboard = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  if (hasNav)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: AppColors.nearBlack),
                      ),
                    ),
                  Text('Leaderboard', style: AppTextStyles.screenTitle),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All Time'),
                  Tab(text: 'This Week'),
                  Tab(text: 'Today'),
                ],
              ),
            ),

            Expanded(
              child: leaderboard.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, __) => Center(
                  child: Text('Could not load leaderboard.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.mediumGrey)),
                ),
                data: (users) {
                  final currentId = currentUser?.id ?? '';
                  final entries = _toEntries(users, currentId);

                  Future<void> doRefresh() async =>
                      ref.invalidate(leaderboardProvider);

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // All Time — real Firestore data
                      _LeaderboardList(
                        entries: entries,
                        periodLabel: _periodLabel('alltime'),
                        showComingSoon: false,
                        onRefresh: doRefresh,
                      ),
                      // Weekly — current user only for now
                      _LeaderboardList(
                        entries: entries
                            .where((e) => e.isCurrentUser)
                            .toList(),
                        periodLabel: _periodLabel('weekly'),
                        showComingSoon: true,
                        onRefresh: doRefresh,
                      ),
                      // Daily — current user only for now
                      _LeaderboardList(
                        entries: entries
                            .where((e) => e.isCurrentUser)
                            .toList(),
                        periodLabel: _periodLabel('daily'),
                        showComingSoon: true,
                        onRefresh: doRefresh,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<_LeaderboardEntry> entries;
  final String periodLabel;
  final bool showComingSoon;
  final Future<void> Function() onRefresh;

  const _LeaderboardList({
    required this.entries,
    required this.periodLabel,
    required this.showComingSoon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: onRefresh,
      child: ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            periodLabel,
            style: AppTextStyles.caption.copyWith(color: AppColors.mediumGrey),
          ),
        ),

        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              'No entries yet.',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGrey),
            ),
          )
        else
          ...entries.asMap().entries.map(
                (e) => _EntryRow(rank: e.key + 1, entry: e.value),
              ),

        if (showComingSoon) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_outlined,
                      size: 20, color: AppColors.mediumGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Global period rankings coming in the next update.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.mediumGrey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ), // end ListView
    ); // end RefreshIndicator
  }
}

class _EntryRow extends StatelessWidget {
  final int rank;
  final _LeaderboardEntry entry;

  const _EntryRow({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final level = XpCalculator.getLevelFromXp(entry.xp);
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser ? AppColors.goldLight : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: entry.isCurrentUser
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1)
            : Border.all(color: AppColors.borderGrey, width: 0.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              medal ?? '#$rank',
              style: medal != null
                  ? const TextStyle(fontSize: 20)
                  : AppTextStyles.label
                      .copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),

          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.username, style: AppTextStyles.label),
                    if (entry.isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('You',
                            style: AppTextStyles.badgeText
                                .copyWith(fontSize: 9)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                LevelBadge(level: level, compact: true),
              ],
            ),
          ),

          Text(
            '${entry.xp} XP',
            style: AppTextStyles.priceSmall.copyWith(
              fontSize: 14,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
