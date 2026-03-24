import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../services/database_service.dart';

class WalletProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;

  List<Wallet> _wallets = [];

  List<Wallet> get wallets => _wallets;

  Future<void> loadWallets() async {
    _wallets = await _db.getWallets();
    notifyListeners();
  }

  double get totalBalance => _wallets.fold(0, (sum, w) => sum + w.balance);
}
