import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../utils/constants.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        website TEXT,
        password_hash TEXT NOT NULL,
        cash_balance REAL NOT NULL DEFAULT 10000.0,
        xp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_login_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE holdings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        symbol TEXT NOT NULL,
        asset_name TEXT NOT NULL,
        asset_type TEXT NOT NULL,
        shares REAL NOT NULL,
        average_buy_price REAL NOT NULL,
        last_updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        UNIQUE(user_id, symbol)
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        symbol TEXT,
        asset_name TEXT,
        asset_type TEXT,
        shares REAL,
        price_at_time REAL,
        total_amount REAL NOT NULL,
        xp_awarded INTEGER NOT NULL DEFAULT 0,
        profit_or_loss REAL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        token TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }
}
