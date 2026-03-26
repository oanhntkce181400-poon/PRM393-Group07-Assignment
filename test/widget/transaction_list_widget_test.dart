import 'package:expense_tracker/models/wallet.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/screens/transaction_list_screen.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

Widget buildTransactionTestApp({
  required TransactionProvider transactionProvider,
  NotificationProvider? notificationProvider,
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransactionProvider>.value(
        value: transactionProvider,
      ),
      ChangeNotifierProvider<NotificationProvider>.value(
        value: notificationProvider ?? NotificationProvider(),
      ),
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider ?? AuthProvider(),
      ),
    ],
    child: const MaterialApp(home: TransactionListScreen()),
  );
}

void main() {
  group('TransactionListScreen', () {
    testWidgets('shows empty state when no transactions', (tester) async {
      final mockDb = MockDatabaseService();
      when(() => mockDb.getWallets()).thenAnswer(
        (_) async => [
          Wallet(
            id: 1,
            name: 'Vi chinh',
            iconCode: 1,
            budget: 1000000,
            balance: 1000000,
          ),
        ],
      );
      when(
        () => mockDb.getTransactionsWithWallet(),
      ).thenAnswer((_) async => []);

      final provider = TransactionProvider(databaseService: mockDb);
      await provider.refreshData();

      await tester.pumpWidget(
        buildTransactionTestApp(transactionProvider: provider),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Danh sách giao dịch'), findsOneWidget);
      expect(
        find.text('Chưa có giao dịch nào. Nhấn + để thêm mới.'),
        findsOneWidget,
      );
      expect(find.text('Tiện ích nhanh'), findsOneWidget);
    });

    testWidgets('renders transaction rows and summary cards', (tester) async {
      final mockDb = MockDatabaseService();
      when(() => mockDb.getWallets()).thenAnswer(
        (_) async => [
          Wallet(
            id: 1,
            name: 'Vi an uong',
            iconCode: 1,
            budget: 500000,
            balance: 350000,
          ),
          Wallet(
            id: 2,
            name: 'Vi luong',
            iconCode: 2,
            budget: 5000000,
            balance: 5200000,
          ),
        ],
      );
      when(() => mockDb.getTransactionsWithWallet()).thenAnswer(
        (_) async => [
          {
            'id': 11,
            'walletId': 1,
            'amount': 50000.0,
            'transactionType': 'EXPENSE',
            'date': '2026-03-26T08:00:00.000',
            'note': 'An sang',
            'walletName': 'Vi an uong',
            'walletIconCode': 1,
          },
          {
            'id': 12,
            'walletId': 2,
            'amount': 1000000.0,
            'transactionType': 'INCOME',
            'date': '2026-03-26T09:00:00.000',
            'note': 'Nhan luong',
            'walletName': 'Vi luong',
            'walletIconCode': 2,
          },
        ],
      );

      final provider = TransactionProvider(databaseService: mockDb);
      await provider.refreshData();

      await tester.pumpWidget(
        buildTransactionTestApp(transactionProvider: provider),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Thu nhập'), findsOneWidget);
      expect(find.text('Chi tiêu'), findsOneWidget);
      expect(find.text('An sang'), findsOneWidget);
      expect(find.text('Nhan luong'), findsOneWidget);
      expect(find.textContaining('Vi an uong'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
