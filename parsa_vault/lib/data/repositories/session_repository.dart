import '../database/database_helper.dart';

class SessionRepository {
  final _db = DatabaseHelper.instance;

  Future<String?> getActiveUserId() async {
    final db = await _db.database;
    final maps = await db.query(
      'sessions',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['user_id'] as String;
  }

  Future<void> createSession({
    required String id,
    required String userId,
    required String token,
  }) async {
    final db = await _db.database;
    // Clear any old sessions first
    await db.delete('sessions');
    await db.insert('sessions', {
      'id': id,
      'user_id': userId,
      'token': token,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('sessions');
  }
}
