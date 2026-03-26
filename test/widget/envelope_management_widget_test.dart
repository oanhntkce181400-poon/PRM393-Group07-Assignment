import 'package:expense_tracker/providers/envelope_provider.dart';
import 'package:expense_tracker/screens/envelope_managemet_screen.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

Widget buildEnvelopeTestApp({required EnvelopeProvider provider}) {
  return ChangeNotifierProvider<EnvelopeProvider>.value(
    value: provider,
    child: const MaterialApp(home: EnvelopeManagementScreen()),
  );
}

void main() {
  group('EnvelopeManagementScreen', () {
    testWidgets('shows empty wallet state', (tester) async {
      final mockDb = MockDatabaseService();
      when(() => mockDb.getWallets()).thenAnswer((_) async => []);

      final provider = EnvelopeProvider(databaseService: mockDb);

      await tester.pumpWidget(buildEnvelopeTestApp(provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quản lý túi tiền'), findsOneWidget);
      expect(find.text('Chưa có túi tiền.'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows create dialog and validates required fields', (
      tester,
    ) async {
      final mockDb = MockDatabaseService();
      when(() => mockDb.getWallets()).thenAnswer((_) async => []);

      final provider = EnvelopeProvider(databaseService: mockDb);

      await tester.pumpWidget(buildEnvelopeTestApp(provider: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Tạo túi tiền'), findsOneWidget);
      expect(find.text('Tên túi'), findsOneWidget);
      expect(find.text('Ngân sách'), findsOneWidget);

      await tester.tap(find.text('Tạo'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tên túi.'), findsOneWidget);
      expect(find.text('Vui lòng nhập ngân sách.'), findsOneWidget);
    });
  });
}
