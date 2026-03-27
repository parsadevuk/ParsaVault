import 'constants.dart';

class XpCalculator {
  XpCalculator._();

  static int getLevelFromXp(int xp) {
    final thresholds = AppConstants.levelThresholds;
    int level = 1;
    for (int i = 0; i < thresholds.length; i++) {
      if (xp >= thresholds[i]) {
        level = i + 1;
      }
    }
    return level;
  }

  static String getLevelTitle(int level) {
    final index = (level - 1).clamp(0, AppConstants.levelTitles.length - 1);
    return AppConstants.levelTitles[index];
  }

  static ({int current, int required, double percentage}) getXpProgress(int xp) {
    final level = getLevelFromXp(xp);
    final thresholds = AppConstants.levelThresholds;

    if (level >= 10) {
      final base = thresholds[9];
      final next = base + 3000;
      final progress = xp - base;
      final required = next - base;
      return (
        current: progress,
        required: required,
        percentage: (progress / required).clamp(0.0, 1.0),
      );
    }

    final currentMin = thresholds[level - 1];
    final nextMin = thresholds[level];
    final progress = xp - currentMin;
    final required = nextMin - currentMin;

    return (
      current: progress,
      required: required,
      percentage: (progress / required).clamp(0.0, 1.0),
    );
  }

  static int calculateSellXp({
    required double sellPrice,
    required double avgBuyPrice,
    required double shares,
  }) {
    final returnPercent =
        ((sellPrice - avgBuyPrice) / avgBuyPrice) * 100;

    if (returnPercent > 0.5) {
      // Profitable sell
      final bonus = returnPercent.floor().clamp(0, AppConstants.xpProfitBonusMax);
      return AppConstants.xpSellProfit + bonus;
    } else if (returnPercent < -0.5) {
      // Loss
      return AppConstants.xpSellLoss;
    } else {
      // Break-even
      return AppConstants.xpSellBreakEven;
    }
  }
}
