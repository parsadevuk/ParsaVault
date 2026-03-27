import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/xp_calculator.dart';
import '../../widgets/common/level_badge.dart';

// Mock ghost users for a more fun leaderboard
class _GhostUser {
  final String username;
  final String initials;
  final int allTimeXp;
  final int weeklyXp;
  final int dailyXp;

  const _GhostUser({
    required this.username,
    required this.initials,
    required this.allTimeXp,
    required this.weeklyXp,
    required this.dailyXp,
  });
}

final _ghosts = [
  const _GhostUser(
      username: 'TradingWolf',
      initials: 'TW',
      allTimeXp: 2840,
      weeklyXp: 180,
      dailyXp: 35),
  const _GhostUser(
      username: 'BullRunner',
      initials: 'BR',
      allTimeXp: 1650,
      weeklyXp: 210,
      dailyXp: 50),
  const _GhostUser(
      username: 'CryptoKing',
      initials: 'CK',
      allTimeXp: 980,
      weeklyXp: 95,
      dailyXp: 20),
  const _GhostUser(
      username: 'StockStar',
      initials: 'SS',
      allTimeXp: 3200,
      weeklyXp: 120,
      dailyXp: 15),
  const _GhostUser(
      username: 'VaultPro',
      initials: 'VP',
      allTimeXp: 540,
      weeklyXp: 310,
      dailyXp: 60),
  const _GhostUser(
      username: 'GoldTrader',
      initials: 'GT',
      allTimeXp: 4100,
      weeklyXp: 85,
      dailyXp: 10),
  const _GhostUser(
      username: 'MarketMaven',
      initials: 'MM',
      allTimeXp: 720,
      weeklyXp: 145,
      dailyXp: 25),
];

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

  List<_LeaderboardEntry> _buildEntries(String period, User user) {

    // Get user XP for period
    int userXp;
    switch (period) {
      case 'weekly':
        // Simple: use a fraction of total XP for weekly display in MVP
        userXp = (user.xp * 0.3).round();
        break;
      case 'daily':
        userXp = (user.xp * 0.05).round();
        break;
      default:
        userXp = user.xp;
    }

    // Build ghost entries for period
    final entries = <_LeaderboardEntry>[
      _LeaderboardEntry(
        username: user.username,
        initials: user.initials,
        xp: userXp,
        isCurrentUser: true,
      ),
      ..._ghosts.map((g) => _LeaderboardEntry(
            username: g.username,
            initials: g.initials,
            xp: period == 'weekly'
                ? g.weeklyXp
                : period == 'daily'
                    ? g.dailyXp
                    : g.allTimeXp,
            isCurrentUser: false,
          )),
    ];

    entries.sort((a, b) => b.xp.compareTo(a.xp));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final hasNav = Navigator.of(context).canPop();
    // ref.watch ensures the leaderboard rebuilds whenever XP changes
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
                        _LeaderboardList(entries: _buildEntries('alltime', user)),
                        _LeaderboardList(entries: _buildEntries('weekly', user)),
                        _LeaderboardList(entries: _buildEntries('daily', user)),
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

  const _LeaderboardList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined,
                size: 48, color: AppColors.borderGrey),
            const SizedBox(height: 12),
            Text('Nothing yet.',
                style: AppTextStyles.sectionHeading
                    .copyWith(color: AppColors.mediumGrey)),
            const SizedBox(height: 8),
            Text('Make a trade to show up on the board.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.mediumGrey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      itemCount: entries.length,
      itemBuilder: (_, i) =>
          _EntryRow(rank: i + 1, entry: entries[i]),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final int rank;
  final _LeaderboardEntry entry;

  const _EntryRow({required this.rank, required this.entry});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFD4A843);
    if (rank == 2) return const Color(0xFF9E9E9E);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.mediumGrey;
  }

  @override
  Widget build(BuildContext context) {
    final level = XpCalculator.getLevelFromXp(entry.xp);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.goldLight
            : AppColors.white,
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
              rank <= 3 ? _medal(rank) : '#$rank',
              style: rank <= 3
                  ? const TextStyle(fontSize: 20)
                  : AppTextStyles.label.copyWith(color: _rankColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: entry.isCurrentUser ? AppColors.gold : AppColors.lightGrey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      entry.isCurrentUser ? Colors.white : AppColors.nearBlack,
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
                            style: AppTextStyles.badgeText.copyWith(
                                fontSize: 9)),
                      ),
                    ],
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
              color: entry.isCurrentUser ? AppColors.gold : AppColors.nearBlack,
            ),
          ),
        ],
      ),
    );
  }

  String _medal(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    return '🥉';
  }
}
