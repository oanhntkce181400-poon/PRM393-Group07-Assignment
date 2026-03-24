import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'finance.db');

    // Mở database, nếu chưa tồn tại thì tạo
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            email TEXT PRIMARY KEY,
            fullName TEXT,
            password TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE wallets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            balance REAL,
            userEmail TEXT
          )
        ''');

        print('Database created!');
      },
    );

    return _db!;
  }
}
