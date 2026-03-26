import 'package:expense_tracker/models/goal.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter/foundation.dart';

class GoalProvider extends ChangeNotifier {
  GoalProvider({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  bool _isLoading = false;
  String? _errorMessage;
  List<Goal> _goals = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Goal> get goals => _goals;

  Future<void> loadInitialData() async {
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = await _databaseService.getGoals();
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGoal(Goal goal) async {
    await _databaseService.insertGoal(goal);
    await refreshData();
  }

  Future<void> updateGoal(Goal goal) async {
    await _databaseService.updateGoal(goal);
    await refreshData();
  }

  Future<void> deleteGoal(int goalId) async {
    await _databaseService.deleteGoal(goalId);
    await refreshData();
  }

  Future<Goal?> getGoalById(int goalId) async {
    return _databaseService.getGoalById(goalId);
  }

  // Calculate progress percentage
  double getProgressPercentage(Goal goal) {
    if (goal.targetAmount <= 0) return 0;
    return (goal.currentAmount / goal.targetAmount) * 100;
  }
}
