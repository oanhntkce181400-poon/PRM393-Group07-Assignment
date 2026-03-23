import 'dart:convert';

import 'package:expense_tracker/models/transaction.dart' as app_model;
import 'package:expense_tracker/models/wallet.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class SeedService {
  SeedService._();

  static Future<void> seedInitialData(Database db) async {
    await _seedWallets(db);
    await _seedTransactionsFromJson(db);
  }

  static Future<void> _seedWallets(Database db) async {
    final wallets = <Wallet>[
      Wallet(
        name: 'Tiền trọ',
        iconCode: 0xe88a,
        budget: 2000000,
        balance: 2000000,
      ),
      Wallet(
        name: 'Ăn uống',
        iconCode: 0xe56c,
        budget: 2000000,
        balance: 2000000,
      ),
      Wallet(
        name: 'Mua sắm',
        iconCode: 0xe59c,
        budget: 1000000,
        balance: 1000000,
      ),
    ];

    for (final wallet in wallets) {
      await db.insert('wallets', wallet.toMap());
    }
  }

  static Future<void> _seedTransactionsFromJson(Database db) async {
    final seedFileContent = await rootBundle.loadString(
      'assets/seeds/seedTransaction.json',
    );

    final jsonList = jsonDecode(seedFileContent) as List<dynamic>;
    for (final rawItem in jsonList) {
      final item = rawItem as Map<String, dynamic>;
      final tx = app_model.Transaction(
        walletId: (item['walletId'] as num).toInt(),
        amount: (item['amount'] as num).toDouble(),
        transactionType: (item['transactionType'] as String).toUpperCase(),
        date: item['date'] as String,
        note: (item['note'] as String?) ?? '',
      );

      await db.insert('transactions', tx.toMap());
      await _applyWalletBalanceImpact(
        db,
        walletId: tx.walletId,
        amount: tx.amount,
        transactionType: tx.transactionType,
      );
    }
  }

  static Future<void> _applyWalletBalanceImpact(
    DatabaseExecutor executor, {
    required int walletId,
    required double amount,
    required String transactionType,
  }) async {
    final delta = transactionType == 'EXPENSE' ? -amount : amount;
    await executor.rawUpdate(
      'UPDATE wallets SET balance = balance + ? WHERE id = ?',
      [delta, walletId],
    );
  }
}
