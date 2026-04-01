import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../../models/user.dart';
import '../../models/holding.dart';
import '../../models/app_transaction.dart';
import '../../utils/constants.dart';
import '../../utils/xp_calculator.dart';
import '../repositories/user_repository.dart';
import '../repositories/holding_repository.dart';
import '../repositories/transaction_repository.dart';

const _uuid = Uuid();

class TradeResult {
  final bool success;
  final String? error;
  final int xpAwarded;
  final bool leveledUp;
  final int newLevel;

  const TradeResult({
    required this.success,
    this.error,
    this.xpAwarded = 0,
    this.leveledUp = false,
    this.newLevel = 1,
  });
}

class PortfolioService {
  final _userRepo = UserRepository();
  final _holdingRepo = HoldingRepository();
  final _txRepo = TransactionRepository();

  Future<List<Holding>> getHoldings(String userId) =>
      _holdingRepo.findByUser(userId);

  Future<List<AppTransaction>> getTransactions(String userId) =>
      _txRepo.findByUser(userId);

  Future<TradeResult> buy({
    required User user,
    required String symbol,
    required String assetName,
    required String assetType,
    required double shares,
    required double currentPrice,
  }) async {
    // Floor shares to 5 decimal places — never round up
    final flooredShares = (shares * 100000).floorToDouble() / 100000;

    // Actual cost is based on floored shares — tiny remainder stays in cash
    final actualCost = flooredShares * currentPrice;

    if (flooredShares <= 0 || actualCost > user.cashBalance) {
      return const TradeResult(
        success: false,
        error: "You don't have enough cash for this trade. Reduce the amount or deposit more.",
      );
    }

    // Determine XP
    final isFirstTrade = !(await _txRepo.hasAnyTrades(user.id));
    final xpAwarded =
        isFirstTrade ? AppConstants.xpFirstTrade : AppConstants.xpBuy;

    final newCash = user.cashBalance - actualCost;
    final newXp = user.xp + xpAwarded;
    final oldLevel = user.level;
    final newLevel = XpCalculator.getLevelFromXp(newXp);

    // Update user financials
    await _userRepo.updateFinancials(
      userId: user.id,
      cashBalance: newCash,
      xp: newXp,
      level: newLevel,
    );

    // Update holding
    final existing = await _holdingRepo.findByUserAndSymbol(user.id, symbol);
    if (existing != null) {
      final newTotalShares = existing.shares + flooredShares;
      final newAvgPrice =
          ((existing.shares * existing.averageBuyPrice) + (flooredShares * currentPrice)) /
              newTotalShares;
      await _holdingRepo.update(existing.copyWith(
        shares: newTotalShares,
        averageBuyPrice: newAvgPrice,
        lastUpdatedAt: DateTime.now(),
      ));
    } else {
      await _holdingRepo.upsert(Holding(
        id: _uuid.v4(),
        userId: user.id,
        symbol: symbol,
        assetName: assetName,
        assetType: assetType,
        shares: flooredShares,
        averageBuyPrice: currentPrice,
        lastUpdatedAt: DateTime.now(),
      ));
    }

    // Record transaction
    await _txRepo.insert(AppTransaction(
      id: _uuid.v4(),
      userId: user.id,
      type: 'buy',
      symbol: symbol,
      assetName: assetName,
      assetType: assetType,
      shares: flooredShares,
      priceAtTime: currentPrice,
      totalAmount: actualCost,
      xpAwarded: xpAwarded,
      timestamp: DateTime.now(),
    ));

    return TradeResult(
      success: true,
      xpAwarded: xpAwarded,
      leveledUp: newLevel > oldLevel,
      newLevel: newLevel,
    );
  }

  Future<TradeResult> sell({
    required User user,
    required String symbol,
    required String assetName,
    required String assetType,
    required double shares,
    required double currentPrice,
  }) async {
    final holding = await _holdingRepo.findByUserAndSymbol(user.id, symbol);

    if (holding == null) {
      return const TradeResult(
        success: false,
        error: "You don't own any shares of this asset.",
      );
    }

    if (shares > holding.shares) {
      return TradeResult(
        success: false,
        error:
            'You only own ${holding.shares.toStringAsFixed(holding.shares < 1 ? 6 : 2)} shares.',
      );
    }

    // Floor revenue to 2 decimal places (cents) — fractional cents vanish
    final flooredRevenue = (shares * currentPrice * 100).floorToDouble() / 100;

    final profitOrLoss = (currentPrice - holding.averageBuyPrice) * shares;
    final xpAwarded = XpCalculator.calculateSellXp(
      sellPrice: currentPrice,
      avgBuyPrice: holding.averageBuyPrice,
      shares: shares,
    );

    final newCash = user.cashBalance + flooredRevenue;
    final newXp = (user.xp + xpAwarded).clamp(0, 999999);
    final oldLevel = user.level;
    final newLevel = XpCalculator.getLevelFromXp(newXp);

    await _userRepo.updateFinancials(
      userId: user.id,
      cashBalance: newCash,
      xp: newXp,
      level: newLevel,
    );

    final remainingShares = holding.shares - shares;
    final remainingValue = remainingShares * currentPrice;
    final soldFraction = shares / holding.shares;

    // Delete holding if:
    // - dust position (≤ 0.000001 shares)
    // - remaining value < $0.02 (less than 2 cents — unsellable residual)
    // - sold ≥ 99.5% of position (clean up the remainder automatically)
    final shouldDelete = remainingShares <= 0.000001 ||
        remainingValue < 0.02 ||
        soldFraction >= 0.995;

    if (shouldDelete) {
      await _holdingRepo.deleteBySymbol(user.id, symbol);
    } else {
      await _holdingRepo.update(
          holding.copyWith(shares: remainingShares, lastUpdatedAt: DateTime.now()));
    }

    await _txRepo.insert(AppTransaction(
      id: _uuid.v4(),
      userId: user.id,
      type: 'sell',
      symbol: symbol,
      assetName: assetName,
      assetType: assetType,
      shares: shares,
      priceAtTime: currentPrice,
      totalAmount: flooredRevenue,
      xpAwarded: xpAwarded,
      profitOrLoss: profitOrLoss,
      timestamp: DateTime.now(),
    ));

    return TradeResult(
      success: true,
      xpAwarded: xpAwarded,
      leveledUp: newLevel > oldLevel,
      newLevel: newLevel,
    );
  }

  Future<TradeResult> deposit({required User user, required double amount}) async {
    if (amount <= 0) {
      return const TradeResult(success: false, error: 'Enter an amount.');
    }
    if (amount > AppConstants.maxDepositPerTransaction) {
      return TradeResult(
        success: false,
        error:
            "You can't deposit more than \$${AppConstants.maxDepositPerTransaction.toStringAsFixed(0)} at once.",
      );
    }

    // Deposit rewards XP — +5 per deposit
    const xpAwarded = AppConstants.xpDeposit; // +5
    final newXp = (user.xp + xpAwarded).clamp(0, 999999);
    final newLevel = XpCalculator.getLevelFromXp(newXp);

    await _userRepo.updateFinancials(
      userId: user.id,
      cashBalance: user.cashBalance + amount,
      xp: newXp,
      level: newLevel,
    );

    await _txRepo.insert(AppTransaction(
      id: _uuid.v4(),
      userId: user.id,
      type: 'deposit',
      totalAmount: amount,
      xpAwarded: xpAwarded,
      timestamp: DateTime.now(),
    ));

    return const TradeResult(success: true, xpAwarded: AppConstants.xpDeposit);
  }

  Future<TradeResult> withdraw({required User user, required double amount}) async {
    if (amount <= 0) {
      return const TradeResult(success: false, error: 'Enter an amount.');
    }
    if (amount > user.cashBalance) {
      return TradeResult(
        success: false,
        error:
            'You only have \$${user.cashBalance.toStringAsFixed(2)} to withdraw.',
      );
    }

    const xpAwarded = AppConstants.xpWithdraw;
    final newXp = user.xp + xpAwarded;
    final newLevel = XpCalculator.getLevelFromXp(newXp);

    await _userRepo.updateFinancials(
      userId: user.id,
      cashBalance: user.cashBalance - amount,
      xp: newXp,
      level: newLevel,
    );

    await _txRepo.insert(AppTransaction(
      id: _uuid.v4(),
      userId: user.id,
      type: 'withdraw',
      totalAmount: amount,
      xpAwarded: xpAwarded,
      timestamp: DateTime.now(),
    ));

    return const TradeResult(success: true, xpAwarded: xpAwarded);
  }

  Future<void> resetPortfolio(User user) async {
    await _holdingRepo.deleteAllForUser(user.id);
    await _txRepo.deleteAllForUser(user.id);
    await _userRepo.updateFinancials(
      userId: user.id,
      cashBalance: AppConstants.startingCash,
      xp: user.xp,
      level: user.level,
    );
  }

  Future<void> resetAll(User user) async {
    await _holdingRepo.deleteAllForUser(user.id);
    await _txRepo.deleteAllForUser(user.id);
    await _userRepo.updateFinancials(
      userId: user.id,
      cashBalance: AppConstants.startingCash,
      xp: 0,
      level: 1,
    );
  }
}
