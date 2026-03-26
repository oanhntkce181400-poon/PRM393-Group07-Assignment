import 'package:expense_tracker/models/transaction.dart' as app_model;
import 'package:expense_tracker/models/wallet.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('TransactionProvider', () {
    late MockDatabaseService mockDatabaseService;
    late TransactionProvider provider;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      provider = TransactionProvider(databaseService: mockDatabaseService);
    });

    test('refreshData loads wallets and transactions', () async {
      when(() => mockDatabaseService.getWallets()).thenAnswer(
        (_) async => [
          Wallet(id: 1, name: 'Vi A', iconCode: 10, budget: 1000, balance: 600),
          Wallet(
            id: 2,
            name: 'Vi B',
            iconCode: 20,
            budget: 2000,
            balance: 2500,
          ),
        ],
      );
      when(() => mockDatabaseService.getTransactionsWithWallet()).thenAnswer(
        (_) async => [
          {'walletId': 1, 'amount': 100.0, 'transactionType': 'EXPENSE'},
          {'walletId': 1, 'amount': 200.0, 'transactionType': 'EXPENSE'},
          {'walletId': 2, 'amount': 300.0, 'transactionType': 'INCOME'},
        ],
      );

      await provider.refreshData();

      expect(provider.errorMessage, isNull);
      expect(provider.wallets, hasLength(2));
      expect(provider.transactions, hasLength(3));
      expect(provider.totalBalance, 3100);
      expect(provider.expenseByWallet(), {1: 300.0});
      expect(provider.getWalletName(1), 'Vi A');
      expect(provider.getWalletName(999), 'Unknown');
      expect(provider.getWalletIcon(2), 20);
    });

    test('refreshWalletsOnly sets error when loading wallets fails', () async {
      when(() => mockDatabaseService.getWallets()).thenThrow(Exception('boom'));

      await provider.refreshWalletsOnly();

      expect(provider.errorMessage, contains('Không thể tải danh sách ví'));
      verify(() => mockDatabaseService.getWallets()).called(1);
    });

    test('add update delete transaction call db and refresh', () async {
      final tx = app_model.Transaction(
        walletId: 1,
        amount: 120000,
        transactionType: 'EXPENSE',
        date: '2026-03-26T10:00:00.000',
        note: 'Cafe',
      );

      when(
        () => mockDatabaseService.insertTransaction(tx),
      ).thenAnswer((_) async => 1);
      when(
        () => mockDatabaseService.updateTransaction(tx),
      ).thenAnswer((_) async => 1);
      when(
        () => mockDatabaseService.deleteTransaction(7),
      ).thenAnswer((_) async => 1);
      when(() => mockDatabaseService.getWallets()).thenAnswer((_) async => []);
      when(
        () => mockDatabaseService.getTransactionsWithWallet(),
      ).thenAnswer((_) async => []);

      await provider.addTransaction(tx);
      await provider.updateTransaction(tx);
      await provider.deleteTransaction(7);

      verify(() => mockDatabaseService.insertTransaction(tx)).called(1);
      verify(() => mockDatabaseService.updateTransaction(tx)).called(1);
      verify(() => mockDatabaseService.deleteTransaction(7)).called(1);
      verify(() => mockDatabaseService.getWallets()).called(3);
      verify(() => mockDatabaseService.getTransactionsWithWallet()).called(3);
    });
  });
}
