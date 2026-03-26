import 'package:expense_tracker/models/wallet.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:flutter/foundation.dart';

class EnvelopeProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  bool isLoading = false;
  String? errorMessage;

  List<Wallet> wallets = [];
  Wallet? selectedWallet;
  List<Map<String, dynamic>> selectedWalletTransactions = [];

  String _normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  Future<void> loadWallets() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      wallets = await _db.getWallets();
    } catch (e) {
      errorMessage = 'Lỗi tải túi tiền: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEnvelope(String name, int iconCode, double budget) async {
    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) {
      throw ArgumentError('Vui lòng nhập tên túi tiền.');
    }
    if (normalizedName.length > 40) {
      throw ArgumentError('Tên túi tiền tối đa 40 ký tự.');
    }
    if (!budget.isFinite || budget <= 0) {
      throw ArgumentError('Ngân sách phải lớn hơn 0.');
    }
    if (budget > 1000000000) {
      throw ArgumentError('Ngân sách quá lớn (tối đa 1,000,000,000).');
    }

    final duplicated = wallets.any(
      (wallet) => _normalizeName(wallet.name) == normalizedName,
    );
    if (duplicated) {
      throw StateError('Tên túi tiền đã tồn tại. Vui lòng chọn tên khác.');
    }

    final wallet = Wallet(
      name: name.trim().replaceAll(RegExp(r'\s+'), ' '),
      iconCode: iconCode,
      budget: budget,
      balance: budget,
    );

    await _db.insertWallet(wallet);
    await loadWallets();
  }

  Future<void> loadEnvelopeDetail(int walletId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      selectedWallet = await _db.getWalletById(walletId);
      selectedWalletTransactions = await _db.getTransactionsByWallet(walletId);
    } catch (e) {
      errorMessage = 'Lỗi tải chi tiết túi: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEnvelope({
    required int id,
    required String name,
    required int iconCode,
    required double budget,
  }) async {
    final old = wallets.firstWhere((w) => w.id == id);

    // Giữ số tiền đã tiêu, chỉ cập nhật tên/icon/budget
    final spent = old.budget - old.balance;
    final newBalance = budget - spent;

    final updated = Wallet(
      id: id,
      name: name,
      iconCode: iconCode,
      budget: budget,
      balance: newBalance,
    );

    await _db.updateWalletBasic(updated);
    await loadWallets();
    await loadEnvelopeDetail(id);
  }

  Future<void> topUpManual(int walletId, double amount) async {
    await _db.topUpWalletManual(walletId, amount);
    await loadWallets();
    await loadEnvelopeDetail(walletId);
  }

  Future<void> deleteEnvelope(int walletId) async {
    await _db.deleteWallet(walletId);
    selectedWallet = null;
    selectedWalletTransactions = [];
    await loadWallets();
    notifyListeners();
  }
}
