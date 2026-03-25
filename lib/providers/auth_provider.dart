import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _loggedEmailKey = 'logged_email';
  static const _lastActiveAtKey = 'last_active_at';
  static const Duration _sessionTtl = Duration(days: 14);

  User? currentUser;
  bool initialized = false;
  DateTime? _lastActiveAt;
  Timer? _sessionTimer;

  /// =========================
  /// Getter
  /// =========================
  bool get isLoggedIn {
    if (currentUser == null) {
      return false;
    }

    if (_isSessionExpired()) {
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
    final email = prefs.getString(_loggedEmailKey);
    final lastActiveAtStr = prefs.getString(_lastActiveAtKey);

    if (email != null && lastActiveAtStr != null) {
      final lastActiveAt = DateTime.tryParse(lastActiveAtStr);

      if (lastActiveAt != null &&
          DateTime.now().difference(lastActiveAt) < _sessionTtl) {
        currentUser = User(fullName: '', email: email, password: '');
        _lastActiveAt = lastActiveAt;
        touchSession(forceWrite: true);
      } else {
        await logout();
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
    _lastActiveAt = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedEmailKey, user.email);
    await prefs.setString(_lastActiveAtKey, _lastActiveAt!.toIso8601String());

    _startSessionTimer();
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
    _sessionTimer?.cancel();
    _lastActiveAt = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedEmailKey);
    await prefs.remove(_lastActiveAtKey);

    currentUser = null;
    notifyListeners();
  }

  /// =========================
  /// TIMER
  /// =========================
  bool _isSessionExpired() {
    if (_lastActiveAt == null) {
      return true;
    }
    return DateTime.now().difference(_lastActiveAt!) >= _sessionTtl;
  }

  void touchSession({bool forceWrite = false}) {
    if (currentUser == null) {
      return;
    }

    final now = DateTime.now();
    final shouldWrite =
        forceWrite ||
        _lastActiveAt == null ||
        now.difference(_lastActiveAt!).inMinutes >= 1;

    _lastActiveAt = now;
    _startSessionTimer();

    if (!shouldWrite) {
      return;
    }

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_lastActiveAtKey, now.toIso8601String());
    });
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();

    if (_lastActiveAt == null) {
      return;
    }

    final remaining = _sessionTtl - DateTime.now().difference(_lastActiveAt!);
    if (remaining.inSeconds <= 0) {
      logout();
      return;
    }

    _sessionTimer = Timer(remaining, () {
      logout();
    });
  }
}
