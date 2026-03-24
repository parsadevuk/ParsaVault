import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/holding_model.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'parsa_vault.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        website TEXT,
        password_hash TEXT NOT NULL,
        cash_balance REAL NOT NULL DEFAULT 10000.0,
        xp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE holdings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        symbol TEXT NOT NULL,
        name TEXT NOT NULL,
        shares REAL NOT NULL,
        average_buy_price REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        symbol TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        shares REAL NOT NULL,
        price_per_share REAL NOT NULL,
        total_value REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  // --- User operations ---

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = base64Encode(bytes);
    return hash;
  }

  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  Future<UserModel?> registerUser({
    required String fullName,
    required String username,
    required String email,
    String? website,
    required String password,
  }) async {
    final db = await database;

    final existing = await db.query(
      'users',
      where: 'email = ? OR username = ?',
      whereArgs: [email, username],
    );

    if (existing.isNotEmpty) return null;

    final user = UserModel(
      fullName: fullName,
      username: username,
      email: email,
      website: website,
      passwordHash: _hashPassword(password),
    );

    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<UserModel?> loginUser({
    required String emailOrUsername,
    required String password,
  }) async {
    final db = await database;

    final results = await db.query(
      'users',
      where: 'email = ? OR username = ?',
      whereArgs: [emailOrUsername, emailOrUsername],
    );

    if (results.isEmpty) return null;

    final user = UserModel.fromMap(results.first);
    if (!_verifyPassword(password, user.passwordHash)) return null;

    return user;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<void> updateUserBalance(int userId, double newBalance) async {
    final db = await database;
    await db.update(
      'users',
      {'cash_balance': newBalance},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateUserXpAndLevel(int userId, int xp, int level) async {
    final db = await database;
    await db.update(
      'users',
      {'xp': xp, 'level': level},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateUserPassword(int userId, String newPassword) async {
    final db = await database;
    await db.update(
      'users',
      {'password_hash': _hashPassword(newPassword)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // --- Holdings operations ---

  Future<List<HoldingModel>> getHoldings(int userId) async {
    final db = await database;
    final results = await db.query(
      'holdings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return results.map((m) => HoldingModel.fromMap(m)).toList();
  }

  Future<HoldingModel?> getHolding(int userId, String symbol) async {
    final db = await database;
    final results = await db.query(
      'holdings',
      where: 'user_id = ? AND symbol = ?',
      whereArgs: [userId, symbol],
    );
    if (results.isEmpty) return null;
    return HoldingModel.fromMap(results.first);
  }

  Future<void> upsertHolding(HoldingModel holding) async {
    final db = await database;
    final existing = await getHolding(holding.userId, holding.symbol);

    if (existing != null) {
      if (holding.shares <= 0) {
        await db.delete(
          'holdings',
          where: 'user_id = ? AND symbol = ?',
          whereArgs: [holding.userId, holding.symbol],
        );
      } else {
        await db.update(
          'holdings',
          {
            'shares': holding.shares,
            'average_buy_price': holding.averageBuyPrice,
            'name': holding.name,
          },
          where: 'user_id = ? AND symbol = ?',
          whereArgs: [holding.userId, holding.symbol],
        );
      }
    } else if (holding.shares > 0) {
      await db.insert('holdings', holding.toMap());
    }
  }

  // --- Transaction operations ---

  Future<void> addTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactionHistory(int userId) async {
    final db = await database;
    final results = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => TransactionModel.fromMap(m)).toList();
  }

  // --- Reset portfolio ---

  Future<void> resetPortfolio(int userId) async {
    final db = await database;
    await db.delete('holdings', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
    await db.update(
      'users',
      {'cash_balance': 10000.0, 'xp': 0, 'level': 1},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
