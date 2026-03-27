import '../../models/app_transaction.dart';
import '../database/database_helper.dart';

class TransactionRepository {
  final _db = DatabaseHelper.instance;

  Future<List<AppTransaction>> findByUser(String userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return maps.map(AppTransaction.fromMap).toList();
  }

  Future<int> getXpForPeriod(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''SELECT COALESCE(SUM(xp_awarded), 0) as total
         FROM transactions
         WHERE user_id = ? AND timestamp BETWEEN ? AND ?''',
      [userId, start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num).toInt();
  }

  Future<bool> hasAnyTrades(String userId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM transactions WHERE user_id = ? AND type IN ('buy','sell')",
      [userId],
    );
    return (result.first['count'] as int) > 0;
  }

  Future<void> insert(AppTransaction tx) async {
    final db = await _db.database;
    await db.insert('transactions', tx.toMap());
  }

  Future<void> deleteAllForUser(String userId) async {
    final db = await _db.database;
    await db.delete(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
