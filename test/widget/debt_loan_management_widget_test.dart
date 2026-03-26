import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/providers/debt_loan_provider.dart';
import 'package:expense_tracker/screens/debt_loan_management_screen.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class FakeDebt extends Fake implements Debt {}

Widget buildDebtTestApp({required DebtLoanProvider provider}) {
  return ChangeNotifierProvider<DebtLoanProvider>.value(
    value: provider,
    child: const MaterialApp(home: DebtLoanManagementScreen()),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDebt());
  });

  group('DebtLoanManagementScreen', () {
    testWidgets('shows empty state and tab labels', (tester) async {
      final mockDb = MockDatabaseService();
      when(() => mockDb.getDebtsByType('LEND')).thenAnswer((_) async => []);
      when(() => mockDb.getDebtsByType('BORROW')).thenAnswer((_) async => []);

      final provider = DebtLoanProvider(databaseService: mockDb);

      await tester.pumpWidget(buildDebtTestApp(provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quản lý nợ / vay'), findsOneWidget);
      expect(find.text('Tiền cho mượn'), findsOneWidget);
      expect(find.text('Tiền đi vay'), findsOneWidget);
      expect(
        find.text('Chưa có dữ liệu. Nhấn nút thêm để tạo mới.'),
        findsOneWidget,
      );
    });

    testWidgets('opens add debt dialog when tapping fab', (tester) async {
      final mockDb = MockDatabaseService();
      when(() => mockDb.getDebtsByType('LEND')).thenAnswer(
        (_) async => [
          Debt(
            id: 1,
            partnerName: 'Minh',
            debtType: 'LEND',
            amount: 500000,
            dueDate: '2026-04-01T00:00:00.000',
            status: 0,
          ),
        ],
      );
      when(() => mockDb.getDebtsByType('BORROW')).thenAnswer((_) async => []);
      when(() => mockDb.insertDebt(any())).thenAnswer((_) async => 1);

      final provider = DebtLoanProvider(databaseService: mockDb);

      await tester.pumpWidget(buildDebtTestApp(provider: provider));
      await tester.pumpAndSettle();

      expect(find.textContaining('Thêm khoản cho mượn'), findsOneWidget);

      await tester.tap(find.textContaining('Thêm khoản cho mượn'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm tiền cho mượn'), findsOneWidget);
      expect(find.text('Tên người mượn tiền'), findsOneWidget);
      expect(find.text('Lưu khoản cho mượn'), findsOneWidget);
    });
  });
}
