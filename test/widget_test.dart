import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/screens/transaction_list_screen.dart';

void main() {
  testWidgets('app boots to transaction list', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.byType(TransactionListScreen), findsOneWidget);
  });
}
