import 'package:expense_tracker/models/goal.dart';
import 'package:expense_tracker/providers/goal_provider.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('GoalProvider', () {
    late MockDatabaseService mockDatabaseService;
    late GoalProvider provider;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      provider = GoalProvider(databaseService: mockDatabaseService);
    });

    test('refreshData loads goals', () async {
      final goals = [
        Goal(
          id: 1,
          name: 'Mua laptop',
          targetAmount: 20000000,
          currentAmount: 5000000,
          startDate: '2026-01-01',
          endDate: '2026-12-31',
        ),
      ];
      when(() => mockDatabaseService.getGoals()).thenAnswer((_) async => goals);

      await provider.refreshData();

      expect(provider.errorMessage, isNull);
      expect(provider.goals, goals);
    });

    test('addGoal inserts and refreshes', () async {
      final goal = Goal(
        name: 'Du lich',
        targetAmount: 5000000,
        currentAmount: 0,
        startDate: '2026-03-01',
        endDate: '2026-08-01',
      );
      when(
        () => mockDatabaseService.insertGoal(goal),
      ).thenAnswer((_) async => 1);
      when(
        () => mockDatabaseService.getGoals(),
      ).thenAnswer((_) async => [goal]);

      await provider.addGoal(goal);

      verify(() => mockDatabaseService.insertGoal(goal)).called(1);
      verify(() => mockDatabaseService.getGoals()).called(1);
      expect(provider.goals, hasLength(1));
    });

    test('getProgressPercentage handles zero target and normal target', () {
      final zeroTarget = Goal(
        name: 'Zero',
        targetAmount: 0,
        currentAmount: 1000,
        startDate: '2026-03-01',
        endDate: '2026-08-01',
      );
      final normal = Goal(
        name: 'Normal',
        targetAmount: 2000,
        currentAmount: 500,
        startDate: '2026-03-01',
        endDate: '2026-08-01',
      );

      expect(provider.getProgressPercentage(zeroTarget), 0);
      expect(provider.getProgressPercentage(normal), 25);
    });
  });
}
