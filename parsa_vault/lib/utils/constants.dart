class AppConstants {
  AppConstants._();

  static const double startingCash = 10000.0;
  static const double maxDepositPerTransaction = 50000.0;
  static const int priceUpdateIntervalSeconds = 30;
  static const int splashMinDurationMs = 3000;
  static const String dbName = 'parsa_vault.db';
  static const int dbVersion = 1;

  // XP awards
  static const int xpFirstTrade = 50;
  static const int xpBuy = 10;
  static const int xpSellProfit = 25;
  static const int xpSellLoss = -5; // Penalty: selling at a loss costs XP
  static const int xpSellBreakEven = 10;
  static const int xpDeposit = 5;  // Reward: each deposit
  static const int xpWithdraw = 5; // Reward: each withdrawal
  static const int xpDailyLogin = 5;
  static const int xpProfitBonusMax = 50;

  // Level thresholds
  static const List<int> levelThresholds = [
    0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 9000,
  ];

  static const List<String> levelTitles = [
    'Apprentice',
    'Trader',
    'Investor',
    'Analyst',
    'Strategist',
    'Portfolio Manager',
    'Fund Manager',
    'Market Expert',
    'Wall Street Pro',
    'Vault Master',
  ];
}
