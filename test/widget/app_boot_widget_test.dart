import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/widgets/auth_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots and renders auth flow', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pump();

    expect(find.byType(AuthGate), findsOneWidget);
  });
}
