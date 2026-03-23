import 'package:expense_tracker/models/transaction.dart' as app_model;
import 'package:expense_tracker/models/wallet.dart';
import 'package:expense_tracker/services/seed_service.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();
  static const _databaseName = 'expense_tracker.db';
  static const _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbFolderPath = await getDatabasesPath();
    final dbPath = '$dbFolderPath/$_databaseName';

    return openDatabase(
      dbPath,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
			CREATE TABLE wallets(
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				name TEXT NOT NULL,
				iconCode INTEGER NOT NULL,
				budget REAL NOT NULL,
				balance REAL NOT NULL
			)
		''');

    await db.execute('''
			CREATE TABLE transactions(
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				walletId INTEGER NOT NULL,
				amount REAL NOT NULL,
				transactionType TEXT NOT NULL,
				date TEXT NOT NULL,
				note TEXT,
				FOREIGN KEY (walletId) REFERENCES wallets(id) ON DELETE RESTRICT
			)
		''');

    await SeedService.seedInitialData(db);
  }

  Future<List<Wallet>> getWallets() async {
    final db = await database;
    final result = await db.query('wallets', orderBy: 'name ASC');
    return result.map(Wallet.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getTransactionsWithWallet() async {
    final db = await database;
    return db.rawQuery('''
			SELECT
				t.id,
				t.walletId,
				t.amount,
				t.transactionType,
				t.date,
				t.note,
				w.name AS walletName,
				w.iconCode AS walletIconCode
			FROM transactions t
			INNER JOIN wallets w ON w.id = t.walletId
			ORDER BY t.date DESC, t.id DESC
		''');
  }

  Future<Map<String, dynamic>?> getTransactionDetail(int transactionId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
			SELECT
				t.id,
				t.walletId,
				t.amount,
				t.transactionType,
				t.date,
				t.note,
				w.name AS walletName,
				w.iconCode AS walletIconCode
			FROM transactions t
			INNER JOIN wallets w ON w.id = t.walletId
			WHERE t.id = ?
		''',
      [transactionId],
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> insertTransaction(app_model.Transaction transaction) async {
    final db = await database;
    return db.transaction((txn) async {
      final insertedId = await txn.insert('transactions', transaction.toMap());
      await _applyWalletBalanceImpact(
        txn,
        walletId: transaction.walletId,
        amount: transaction.amount,
        transactionType: transaction.transactionType,
        reverse: false,
      );
      return insertedId;
    });
  }

  Future<int> updateTransaction(app_model.Transaction transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaction id is required for update.');
    }

    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      if (existing.isEmpty) {
        throw StateError('Transaction not found.');
      }

      final oldTx = app_model.Transaction.fromMap(existing.first);
      await _applyWalletBalanceImpact(
        txn,
        walletId: oldTx.walletId,
        amount: oldTx.amount,
        transactionType: oldTx.transactionType,
        reverse: true,
      );

      final updatedRows = await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      await _applyWalletBalanceImpact(
        txn,
        walletId: transaction.walletId,
        amount: transaction.amount,
        transactionType: transaction.transactionType,
        reverse: false,
      );

      return updatedRows;
    });
  }

  Future<int> deleteTransaction(int transactionId) async {
    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (existing.isEmpty) {
        return 0;
      }

      final deletedTx = app_model.Transaction.fromMap(existing.first);
      await _applyWalletBalanceImpact(
        txn,
        walletId: deletedTx.walletId,
        amount: deletedTx.amount,
        transactionType: deletedTx.transactionType,
        reverse: true,
      );

      return txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  Future<void> _applyWalletBalanceImpact(
    DatabaseExecutor executor, {
    required int walletId,
    required double amount,
    required String transactionType,
    required bool reverse,
  }) async {
    var delta = transactionType == 'EXPENSE' ? -amount : amount;
    if (reverse) {
      delta = -delta;
    }

    await executor.rawUpdate(
      'UPDATE wallets SET balance = balance + ? WHERE id = ?',
      [delta, walletId],
    );
  }
}
