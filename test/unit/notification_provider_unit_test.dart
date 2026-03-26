import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('NotificationProvider', () {
    late MockDatabaseService mockDatabaseService;
    late NotificationProvider provider;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      provider = NotificationProvider(databaseService: mockDatabaseService);
    });

    test('refreshData updates notifications and unreadCount', () async {
      final notifications = [
        {'id': 1, 'title': 'A', 'isRead': 0},
        {'id': 2, 'title': 'B', 'isRead': 1},
        {'id': 3, 'title': 'C', 'isRead': 0},
      ];
      when(
        () => mockDatabaseService.getNotifications(),
      ).thenAnswer((_) async => notifications);

      await provider.refreshData();

      expect(provider.errorMessage, isNull);
      expect(provider.notifications, hasLength(3));
      expect(provider.unreadCount, 2);
    });

    test(
      'markAllAsRead marks local notifications read and resets unread',
      () async {
        when(() => mockDatabaseService.getNotifications()).thenAnswer(
          (_) async => [
            {'id': 1, 'title': 'A', 'isRead': 0},
            {'id': 2, 'title': 'B', 'isRead': 0},
          ],
        );
        when(
          () => mockDatabaseService.markAllNotificationsAsRead(),
        ).thenAnswer((_) async {});

        await provider.refreshData();
        await provider.markAllAsRead();

        expect(provider.unreadCount, 0);
        expect(
          provider.notifications.every((item) => item['isRead'] == 1),
          isTrue,
        );
        verify(
          () => mockDatabaseService.markAllNotificationsAsRead(),
        ).called(1);
      },
    );
  });
}
