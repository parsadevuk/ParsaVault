import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
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

  /// Start of the current UTC day.
  DateTime get _todayUtc {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  /// Start of the current UTC week (Monday 00:00 UTC = Greenwich).
  DateTime get _weekStartUtc {
    final today = _todayUtc;
    // weekday: 1=Mon … 7=Sun
    final daysFromMonday = today.weekday - 1;
    return today.subtract(Duration(days: daysFromMonday));
  }

  List<_LeaderboardEntry> _buildEntries(String period, User user) {
    // All Time: use full XP
    // This Week / Today: Phase 2 (Firestore) will track per-period XP.
    // For now show total XP in all tabs — real period tracking coming soon.
    final xp = user.xp;

    return [
      _LeaderboardEntry(
        username: user.username,
        initials: user.initials,
        xp: xp,
        isCurrentUser: true,
      ),
    ];
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

  @override
  Widget build(BuildContext context) {
    final hasNav = Navigator.of(context).canPop();
    // ref.watch so leaderboard rebuilds immediately when XP changes
    final user = ref.watch(authProvider).user;

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
              child: user == null
                  ? const SizedBox.shrink()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _LeaderboardList(
                          entries: _buildEntries('alltime', user),
                          periodLabel: _periodLabel('alltime'),
                        ),
                        _LeaderboardList(
                          entries: _buildEntries('weekly', user),
                          periodLabel: _periodLabel('weekly'),
                        ),
                        _LeaderboardList(
                          entries: _buildEntries('daily', user),
                          periodLabel: _periodLabel('daily'),
                        ),
                      ],
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

  const _LeaderboardList({
    required this.entries,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        // Period label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            periodLabel,
            style: AppTextStyles.caption.copyWith(color: AppColors.mediumGrey),
          ),
        ),

        // Real user entries
        ...entries.map((e) => _EntryRow(rank: 1, entry: e)),

        // Coming soon notice
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
                    'Full leaderboard with all players launches with cloud sync in the next update.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mediumGrey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final int rank;
  final _LeaderboardEntry entry;

  const _EntryRow({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final level = XpCalculator.getLevelFromXp(entry.xp);

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
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              rank == 1 ? '🥇' : '#$rank',
              style: rank == 1
                  ? const TextStyle(fontSize: 20)
                  : AppTextStyles.label
                      .copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
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

          // Username + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.username, style: AppTextStyles.label),
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
                ),
                const SizedBox(height: 2),
                LevelBadge(level: level, compact: true),
              ],
            ),
          ),

          // XP
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
