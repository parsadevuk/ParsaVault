import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class XpService {
  static final XpService instance = XpService._internal();
  XpService._internal();

  // XP awards
  static const int xpPerTrade = 10;
  static const int xpProfitableTrade = 25;
  static const int xpFirstTradeOfDay = 15;

  // Level thresholds
  static final List<int> levelThresholds = _generateThresholds();

  static List<int> _generateThresholds() {
    final thresholds = <int>[0, 100, 250, 500, 1000];
    // Generate further levels by doubling
    for (int i = 5; i < 50; i++) {
      thresholds.add(thresholds.last * 2);
    }
    return thresholds;
  }

  int getLevelForXp(int totalXp) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (totalXp >= levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  int getXpForNextLevel(int level) {
    if (level < levelThresholds.length) {
      return levelThresholds[level];
    }
    return levelThresholds.last * 2;
  }

  int getXpForCurrentLevel(int level) {
    if (level - 1 >= 0 && level - 1 < levelThresholds.length) {
      return levelThresholds[level - 1];
    }
    return 0;
  }

  double getProgressToNextLevel(int totalXp, int level) {
    final currentThreshold = getXpForCurrentLevel(level);
    final nextThreshold = getXpForNextLevel(level);
    final range = nextThreshold - currentThreshold;
    if (range <= 0) return 1.0;
    return ((totalXp - currentThreshold) / range).clamp(0.0, 1.0);
  }

  Future<int> calculateXpForTrade({
    required int userId,
    required bool isProfitable,
  }) async {
    int xpEarned = xpPerTrade;

    if (isProfitable) {
      xpEarned += xpProfitableTrade;
    }

    // Check if first trade of the day
    final prefs = await SharedPreferences.getInstance();
    final lastTradeDate = prefs.getString('last_trade_date_$userId');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastTradeDate != today) {
      xpEarned += xpFirstTradeOfDay;
      await prefs.setString('last_trade_date_$userId', today);
    }

    return xpEarned;
  }

  Future<Map<String, int>> awardXp({
    required int userId,
    required int currentXp,
    required bool isProfitable,
  }) async {
    final xpEarned = await calculateXpForTrade(
      userId: userId,
      isProfitable: isProfitable,
    );

    final newXp = currentXp + xpEarned;
    final newLevel = getLevelForXp(newXp);

    await DatabaseService.instance.updateUserXpAndLevel(userId, newXp, newLevel);

    return {
      'xpEarned': xpEarned,
      'totalXp': newXp,
      'level': newLevel,
    };
  }
}
