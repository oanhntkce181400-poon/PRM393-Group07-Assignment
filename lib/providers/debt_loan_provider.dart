import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter/foundation.dart';

class DebtLoanProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  bool _isLoading = false;
  String? _errorMessage;
  List<Debt> _lendDebts = [];
  List<Debt> _borrowDebts = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Debt> get lendDebts => _lendDebts;
  List<Debt> get borrowDebts => _borrowDebts;

  Future<void> loadInitialData() async {
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lendDebts = await _databaseService.getDebtsByType('LEND');
      _borrowDebts = await _databaseService.getDebtsByType('BORROW');
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách nợ: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDebt(Debt debt) async {
    await _databaseService.insertDebt(debt);
    await refreshData();
  }

  Future<void> updateDebt(Debt debt) async {
    await _databaseService.updateDebt(debt);
    await refreshData();
  }

  Future<void> deleteDebt(int debtId) async {
    await _databaseService.deleteDebt(debtId);
    await refreshData();
  }

  Future<void> markDebtPaid(int debtId, bool isPaid) async {
    await _databaseService.markDebtPaid(debtId, isPaid);
    await refreshData();
  }
}
