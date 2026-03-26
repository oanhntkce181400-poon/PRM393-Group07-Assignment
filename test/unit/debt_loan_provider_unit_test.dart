import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/providers/debt_loan_provider.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('DebtLoanProvider', () {
    late MockDatabaseService mockDatabaseService;
    late DebtLoanProvider provider;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      provider = DebtLoanProvider(databaseService: mockDatabaseService);
    });

    test('refreshData loads lend and borrow debts', () async {
      final lendDebts = [
        Debt(
          id: 1,
          partnerName: 'A',
          debtType: 'LEND',
          amount: 100000,
          dueDate: '2026-04-01',
          status: 0,
        ),
      ];
      final borrowDebts = [
        Debt(
          id: 2,
          partnerName: 'B',
          debtType: 'BORROW',
          amount: 200000,
          dueDate: '2026-04-02',
          status: 1,
        ),
      ];

      when(
        () => mockDatabaseService.getDebtsByType('LEND'),
      ).thenAnswer((_) async => lendDebts);
      when(
        () => mockDatabaseService.getDebtsByType('BORROW'),
      ).thenAnswer((_) async => borrowDebts);

      await provider.refreshData();

      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.lendDebts, lendDebts);
      expect(provider.borrowDebts, borrowDebts);
      verify(() => mockDatabaseService.getDebtsByType('LEND')).called(1);
      verify(() => mockDatabaseService.getDebtsByType('BORROW')).called(1);
    });

    test('refreshData sets errorMessage on exception', () async {
      when(
        () => mockDatabaseService.getDebtsByType('LEND'),
      ).thenThrow(Exception('db error'));
      when(
        () => mockDatabaseService.getDebtsByType('BORROW'),
      ).thenAnswer((_) async => []);

      await provider.refreshData();

      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('Không thể tải danh sách nợ'));
      expect(provider.lendDebts, isEmpty);
      expect(provider.borrowDebts, isEmpty);
    });

    test('addDebt inserts then refreshes list', () async {
      final debt = Debt(
        partnerName: 'C',
        debtType: 'LEND',
        amount: 300000,
        dueDate: '2026-04-03',
        status: 0,
      );

      when(
        () => mockDatabaseService.insertDebt(debt),
      ).thenAnswer((_) async => 1);
      when(
        () => mockDatabaseService.getDebtsByType('LEND'),
      ).thenAnswer((_) async => [debt]);
      when(
        () => mockDatabaseService.getDebtsByType('BORROW'),
      ).thenAnswer((_) async => []);

      await provider.addDebt(debt);

      verify(() => mockDatabaseService.insertDebt(debt)).called(1);
      verify(() => mockDatabaseService.getDebtsByType('LEND')).called(1);
      verify(() => mockDatabaseService.getDebtsByType('BORROW')).called(1);
      expect(provider.lendDebts, hasLength(1));
    });

    test('markDebtPaid updates status then refreshes', () async {
      when(
        () => mockDatabaseService.markDebtPaid(99, true),
      ).thenAnswer((_) async => 1);
      when(
        () => mockDatabaseService.getDebtsByType('LEND'),
      ).thenAnswer((_) async => []);
      when(
        () => mockDatabaseService.getDebtsByType('BORROW'),
      ).thenAnswer((_) async => []);

      await provider.markDebtPaid(99, true);

      verify(() => mockDatabaseService.markDebtPaid(99, true)).called(1);
      verify(() => mockDatabaseService.getDebtsByType('LEND')).called(1);
      verify(() => mockDatabaseService.getDebtsByType('BORROW')).called(1);
    });
  });
}
