import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/models/goal.dart';
import 'package:expense_tracker/models/transaction.dart' as app_model;
import 'package:expense_tracker/models/wallet.dart';
import 'package:expense_tracker/services/seed_service.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();
  static const _databaseName = 'expense_tracker.db';
  static const _databaseVersion = 3;

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
      onUpgrade: _onUpgrade,
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

    await _createGoalsTable(db);
    await _createDebtTable(db);
    await _createNotificationTable(db);

    await SeedService.seedInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createGoalsTable(db);
      await _createDebtTable(db);
      await _createNotificationTable(db);
    }

    if (oldVersion < 3) {
      await _ensureNotificationReadColumn(db);
    }
  }

  Future<void> _createDebtTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        partnerName TEXT NOT NULL,
        debtType TEXT NOT NULL,
        amount REAL NOT NULL,
        dueDate TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createNotificationTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS system_notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        referenceId INTEGER,
        createdAt TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _ensureNotificationReadColumn(Database db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(system_notifications)',
    );
    final hasReadColumn = columns.any((item) => item['name'] == 'isRead');
    if (hasReadColumn) {
      return;
    }

    await db.execute(
      'ALTER TABLE system_notifications ADD COLUMN isRead INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _createGoalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL
      )
    ''');
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
      await _createLowBalanceNotificationIfNeeded(txn, transaction.walletId);
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

      await _createLowBalanceNotificationIfNeeded(txn, oldTx.walletId);
      if (oldTx.walletId != transaction.walletId) {
        await _createLowBalanceNotificationIfNeeded(txn, transaction.walletId);
      }

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

      await _createLowBalanceNotificationIfNeeded(txn, deletedTx.walletId);

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

  // Goals Methods
  Future<List<Goal>> getGoals() async {
    final db = await database;
    final result = await db.query('goals', orderBy: 'endDate ASC');
    return result.map(Goal.fromMap).toList();
  }

  Future<Goal?> getGoalById(int id) async {
    final db = await database;
    final result = await db.query('goals', where: 'id = ?', whereArgs: [id]);

    if (result.isEmpty) {
      return null;
    }

    return Goal.fromMap(result.first);
  }

  Future<int> insertGoal(Goal goal) async {
    final db = await database;
    return db.insert('goals', goal.toMap());
  }

  Future<int> updateGoal(Goal goal) async {
    if (goal.id == null) {
      throw ArgumentError('Goal id is required for update.');
    }

    final db = await database;
    return db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // Debt Methods
  Future<List<Debt>> getDebtsByType(String debtType) async {
    final db = await database;
    final result = await db.query(
      'debts',
      where: 'debtType = ?',
      whereArgs: [debtType],
      orderBy: 'status ASC, dueDate ASC, id DESC',
    );
    return result.map(Debt.fromMap).toList();
  }

  Future<int> insertDebt(Debt debt) async {
    final db = await database;
    return db.insert('debts', debt.toMap());
  }

  Future<int> updateDebt(Debt debt) async {
    if (debt.id == null) {
      throw ArgumentError('Debt id is required for update.');
    }

    final db = await database;
    return db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<int> deleteDebt(int debtId) async {
    final db = await database;
    return db.delete('debts', where: 'id = ?', whereArgs: [debtId]);
  }

  Future<int> markDebtPaid(int debtId, bool isPaid) async {
    final db = await database;
    return db.update(
      'debts',
      {'status': isPaid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    await syncLowBalanceNotificationsForAllWallets();
    await ensureDailyReminderNotification();
    final db = await database;
    return db.query('system_notifications', orderBy: 'createdAt DESC, id DESC');
  }

  Future<void> syncLowBalanceNotificationsForAllWallets() async {
    final db = await database;
    final walletRows = await db.query('wallets', columns: ['id']);

    for (final wallet in walletRows) {
      final walletId = (wallet['id'] as num?)?.toInt();
      if (walletId == null) {
        continue;
      }
      await _createLowBalanceNotificationIfNeeded(db, walletId);
    }
  }

  Future<int> getUnreadNotificationCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS unreadTotal FROM system_notifications WHERE isRead = 0',
    );

    if (result.isEmpty) {
      return 0;
    }

    return ((result.first['unreadTotal'] as num?) ?? 0).toInt();
  }

  Future<void> markAllNotificationsAsRead() async {
    final db = await database;
    await db.update('system_notifications', {'isRead': 1}, where: 'isRead = 0');
  }

  Future<void> ensureDailyReminderNotification() async {
    final now = DateTime.now();
    if (now.hour < 20) {
      return;
    }

    final db = await database;
    final datePrefix = now.toIso8601String().split('T').first;
    final existing = await db.query(
      'system_notifications',
      where: 'type = ? AND createdAt LIKE ?',
      whereArgs: ['DAILY_REMINDER', '$datePrefix%'],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return;
    }

    await db.insert('system_notifications', {
      'type': 'DAILY_REMINDER',
      'title': 'Nhắc nhở buổi tối',
      'message':
          'Đừng quên nhập chi tiêu hôm nay để theo dõi chính xác hơn nhé.',
      'referenceId': null,
      'createdAt': now.toIso8601String(),
      'isRead': 0,
    });
  }

  Future<void> _createLowBalanceNotificationIfNeeded(
    DatabaseExecutor executor,
    int walletId,
  ) async {
    final walletRows = await executor.query(
      'wallets',
      columns: ['name', 'budget', 'balance'],
      where: 'id = ?',
      whereArgs: [walletId],
      limit: 1,
    );

    if (walletRows.isEmpty) {
      return;
    }

    final wallet = walletRows.first;
    final walletName = (wallet['name'] as String?) ?? 'Ví';
    final budget = (wallet['budget'] as num?)?.toDouble() ?? 0;
    final balance = (wallet['balance'] as num?)?.toDouble() ?? 0;

    if (budget <= 0) {
      return;
    }

    String? alertType;
    String? message;

    if (balance < 0) {
      alertType = 'LOW_BALANCE_NEGATIVE';
      message = 'Cảnh báo: $walletName đã âm tiền. Bạn cần cân đối lại ngay!';
    } else if (balance == 0) {
      alertType = 'LOW_BALANCE_EMPTY';
      message = 'Cảnh báo: $walletName của bạn đã hết tiền!';
    } else if (balance <= budget * 0.2) {
      alertType = 'LOW_BALANCE_20';
      message = 'Cảnh báo: $walletName của bạn sắp cạn (dưới 20% ngân sách).';
    }

    if (alertType == null || message == null) {
      return;
    }

    final datePrefix = DateTime.now().toIso8601String().split('T').first;
    final existing = await executor.query(
      'system_notifications',
      where: 'type = ? AND referenceId = ? AND createdAt LIKE ?',
      whereArgs: [alertType, walletId, '$datePrefix%'],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return;
    }

    await executor.insert('system_notifications', {
      'type': alertType,
      'title': 'Cảnh báo số dư ví',
      'message': message,
      'referenceId': walletId,
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': 0,
    });
  }

  // ===== ENVELOPE =====

  Future<int> insertWallet(Wallet wallet) async {
    final db = await database;
    return db.insert('wallets', wallet.toMap());
  }

  Future<int> updateWalletBasic(Wallet wallet) async {
    if (wallet.id == null) {
      throw ArgumentError('Wallet id is required.');
    }

    final db = await database;
    return db.transaction((txn) async {
      final updatedRows = await txn.update(
        'wallets',
        wallet.toMap(),
        where: 'id = ?',
        whereArgs: [wallet.id],
      );
      await _createLowBalanceNotificationIfNeeded(txn, wallet.id!);
      return updatedRows;
    });
  }

  Future<int> topUpWalletManual(int walletId, double amount) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be > 0');
    }

    final db = await database;

    return db.transaction((txn) async {
      // Nạp tiền thủ công: tăng budget + balance để progress bar vẫn đúng
      final updatedRows = await txn.rawUpdate(
        'UPDATE wallets SET budget = budget + ?, balance = balance + ? WHERE id = ?',
        [amount, amount, walletId],
      );
      await _createLowBalanceNotificationIfNeeded(txn, walletId);
      return updatedRows;
    });
  }

  Future<Wallet?> getWalletById(int walletId) async {
    final db = await database;
    final rows = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [walletId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return Wallet.fromMap(rows.first);
  }

  Future<List<Map<String, dynamic>>> getTransactionsByWallet(
    int walletId,
  ) async {
    final db = await database;

    // Lấy thu/chi của đúng 1 túi tiền
    return db.query(
      'transactions',
      where: 'walletId = ?',
      whereArgs: [walletId],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<int> deleteWallet(int walletId) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete(
        'system_notifications',
        where: 'referenceId = ?',
        whereArgs: [walletId],
      );
      await txn.delete(
        'transactions',
        where: 'walletId = ?',
        whereArgs: [walletId],
      );
      return txn.delete('wallets', where: 'id = ?', whereArgs: [walletId]);
    });
  }
}
