import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/database_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  /// ================= STATE =================
  bool _isLoading = false;
  String? _errorMessage;

  List<Wallet> _wallets = [];
  List<Map<String, dynamic>> _transactions = [];

  /// ================= GETTER =================
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Wallet> get wallets => _wallets;
  List<Map<String, dynamic>> get transactions => _transactions;

  /// ================= LOAD DATA =================
  Future<void> loadInitialData() async {
    await refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _wallets = await _databaseService.getWallets();
      _transactions = await _databaseService.getTransactionsWithWallet();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// ================= CRUD TRANSACTION =================

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

  /// =====================================================
  /// 📊 PIE CHART DATA (CHI TIÊU THEO VÍ)
  /// =====================================================
  Map<int, double> expenseByWallet() {
    final Map<int, double> result = {};

    for (final tx in _transactions) {
      if (tx['transactionType'] == 'EXPENSE') {
        final int walletId = tx['walletId'];
        final double amount = (tx['amount'] as num).toDouble();

        result[walletId] = (result[walletId] ?? 0) + amount;
      }
    }

    return result;
  }

  /// =====================================================
  /// 💰 TOTAL BALANCE (TỔNG TIỀN TẤT CẢ VÍ)
  /// =====================================================
  double get totalBalance {
    double total = 0;

    for (final wallet in _wallets) {
      total += wallet.balance;
    }

    return total;
  }

  /// =====================================================
  /// 🧠 HELPER: LẤY TÊN VÍ THEO ID
  /// =====================================================
  String getWalletName(int walletId) {
    try {
      return _wallets.firstWhere((w) => w.id == walletId).name;
    } catch (_) {
      return "Unknown";
    }
  }

  /// =====================================================
  /// 🎨 HELPER: ICON THEO WALLET
  /// =====================================================
  int getWalletIcon(int walletId) {
    try {
      return _wallets.firstWhere((w) => w.id == walletId).iconCode;
    } catch (_) {
      return 0xe3af;
    }
  }

  /// ================= PIE DATA =================
  Map<int, double> expenseByWallet1() {
    Map<int, double> result = {};

    for (var tx in _transactions) {
      if (tx['transactionType'] == 'EXPENSE') {
        final walletId = tx['walletId'];
        final amount = (tx['amount'] as num).toDouble();

        result[walletId] = (result[walletId] ?? 0) + amount;
      }
    }
    return result;
  }

  /// ✅ NEW — TOTAL BALANCE
  double totalBalance1() {
    double total = 0;
    for (var wallet in _wallets) {
      total += wallet.balance;
    }
    return total;
  }

  /// ✅ NEW — Wallet Name
  String getWalletName1(int walletId) {
    return _wallets.firstWhere((w) => w.id == walletId).name;
  }

  double totalBalance2() {
    return _wallets.fold(0.0, (sum, w) => sum + w.balance);
  }
}
