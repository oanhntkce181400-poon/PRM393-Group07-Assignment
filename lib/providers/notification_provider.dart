import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter/foundation.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> loadInitialData() async {
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _databaseService.getNotifications();
      _unreadCount = _notifications
          .where((item) => ((item['isRead'] as num?) ?? 0).toInt() == 0)
          .length;
    } catch (e) {
      _errorMessage = 'Không thể tải thông báo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _databaseService.markAllNotificationsAsRead();
      _notifications = _notifications
          .map((item) => {...item, 'isRead': 1})
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {
      // Keep UI responsive even if marking as read fails.
    }
  }
}
