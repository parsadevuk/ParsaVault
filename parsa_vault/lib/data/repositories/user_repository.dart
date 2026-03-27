import '../../models/user.dart';
import '../database/database_helper.dart';

class UserRepository {
  final _db = DatabaseHelper.instance;

  Future<User?> findById(String id) async {
    final db = await _db.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> findByEmail(String email) async {
    final db = await _db.database;
    final maps = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> findByUsername(String username) async {
    final db = await _db.database;
    final maps = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [username.toLowerCase().trim()],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> findByEmailOrUsername(String value) async {
    final db = await _db.database;
    final lower = value.toLowerCase().trim();
    final maps = await db.query(
      'users',
      where: 'LOWER(email) = ? OR LOWER(username) = ?',
      whereArgs: [lower, lower],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<bool> emailExists(String email) async =>
      (await findByEmail(email)) != null;

  Future<bool> usernameExists(String username) async =>
      (await findByUsername(username)) != null;

  Future<bool> anyUsersExist() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return (result.first['count'] as int) > 0;
  }

  Future<void> insert(User user) async {
    final db = await _db.database;
    await db.insert('users', user.toMap());
  }

  Future<void> update(User user) async {
    final db = await _db.database;
    await db.update('users', user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> updateFinancials({
    required String userId,
    required double cashBalance,
    required int xp,
    required int level,
  }) async {
    final db = await _db.database;
    await db.update(
      'users',
      {
        'cash_balance': cashBalance,
        'xp': xp,
        'level': level,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateLastLogin(String userId) async {
    final db = await _db.database;
    await db.update(
      'users',
      {
        'last_login_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updatePassword(String userId, String newHash) async {
    final db = await _db.database;
    await db.update(
      'users',
      {
        'password_hash': newHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateProfilePicture(
      String userId, String? base64Image) async {
    final db = await _db.database;
    await db.update(
      'users',
      {
        'profile_picture': base64Image,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
