import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/wallet.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter/foundation.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  bool _isLoading = false;
  String? _errorMessage;
  List<Wallet> _wallets = [];
  List<Map<String, dynamic>> _transactions = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Wallet> get wallets => _wallets;
  List<Map<String, dynamic>> get transactions => _transactions;

  Future<void> loadInitialData() async {
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _wallets = await _databaseService.getWallets();
      _transactions = await _databaseService.getTransactionsWithWallet();
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWalletsOnly() async {
    try {
      // [LOAD_WALLETS] Chỉ tải lại danh sách ví, không tải lại transactions.
      _wallets = await _databaseService.getWallets();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách ví: $e';
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _databaseService.insertTransaction(transaction);
    await refreshData();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _databaseService.updateTransaction(transaction);
    await refreshData();
  }

  Future<void> deleteTransaction(int transactionId) async {
    await _databaseService.deleteTransaction(transactionId);
    await refreshData();
  }

  Future<Map<String, dynamic>?> getTransactionDetail(int transactionId) async {
    return _databaseService.getTransactionDetail(transactionId);
  }
}
