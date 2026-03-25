import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? currentUser;
  bool initialized = false;
  DateTime? _loginTime;
  Timer? _logoutTimer;

  /// =========================
  /// Getter
  /// =========================
  bool get isLoggedIn {
    if (currentUser == null) return false;

    // Kiểm tra timeout: 30 phút
    if (_loginTime != null &&
        DateTime.now().difference(_loginTime!).inMinutes >= 30) {
      logout();
      return false;
    }
    return true;
  }

  String? get email => currentUser?.email;

  /// =========================
  /// AUTO LOGIN
  /// =========================
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('logged_email');
    final loginTimeStr = prefs.getString('login_time');

    if (email != null) {
      currentUser = User(fullName: '', email: email, password: '');
      if (loginTimeStr != null) {
        _loginTime = DateTime.parse(loginTimeStr);

        // Nếu chưa quá 1 phút → khởi động timer
        if (DateTime.now().difference(_loginTime!).inMinutes < 1) {
          _startLogoutTimer();
        } else {
          await logout();
        }
      } else {
        _loginTime = DateTime.now();
        _startLogoutTimer();
      }
    }

    initialized = true;
    notifyListeners();
  }

  /// =========================
  /// LOGIN
  /// =========================
  Future<String?> login(String email, String password) async {
    final user = await AuthService.login(email, password);

    if (user == null) return "Sai email hoặc mật khẩu";

    currentUser = user;
    _loginTime = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logged_email', user.email);
    await prefs.setString('login_time', _loginTime!.toIso8601String());

    _startLogoutTimer();
    notifyListeners();
    return null;
  }

  /// =========================
  /// REGISTER
  /// =========================
  Future<String?> register(String name, String email, String password) async {
    return await AuthService.register(
      User(fullName: name, email: email, password: password),
    );
  }

  /// =========================
  /// LOGOUT
  /// =========================
  Future<void> logout() async {
    _logoutTimer?.cancel();
    _loginTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_email');
    await prefs.remove('login_time');

    currentUser = null;
    notifyListeners();
  }

  /// =========================
  /// TIMER
  /// =========================
  void _startLogoutTimer() {
    _logoutTimer?.cancel();

    // thời gian còn lại (60 giây - thời gian đã trôi qua)
    final remaining = 1800 - DateTime.now().difference(_loginTime!).inSeconds;
    if (remaining <= 0) {
      logout();
      return;
    }

    _logoutTimer = Timer(Duration(seconds: remaining), () {
      logout();
    });
  }
}
