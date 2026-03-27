import 'package:sqflite/sqflite.dart';
import '../../models/holding.dart';
import '../database/database_helper.dart';

class HoldingRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Holding>> findByUser(String userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'holdings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'last_updated_at DESC',
    );
    return maps.map(Holding.fromMap).toList();
  }

  Future<Holding?> findByUserAndSymbol(String userId, String symbol) async {
    final db = await _db.database;
    final maps = await db.query(
      'holdings',
      where: 'user_id = ? AND symbol = ?',
      whereArgs: [userId, symbol],
    );
    if (maps.isEmpty) return null;
    return Holding.fromMap(maps.first);
  }

  Future<void> upsert(Holding holding) async {
    final db = await _db.database;
    await db.insert(
      'holdings',
      holding.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Holding holding) async {
    final db = await _db.database;
    await db.update(
      'holdings',
      holding.toMap(),
      where: 'id = ?',
      whereArgs: [holding.id],
    );
  }

  Future<void> delete(String holdingId) async {
    final db = await _db.database;
    await db.delete('holdings', where: 'id = ?', whereArgs: [holdingId]);
  }

  Future<void> deleteAllForUser(String userId) async {
    final db = await _db.database;
    await db.delete('holdings', where: 'user_id = ?', whereArgs: [userId]);
  }
}
