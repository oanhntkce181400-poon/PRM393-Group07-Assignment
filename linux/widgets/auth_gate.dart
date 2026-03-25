import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/transaction_list_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.isLoggedIn) {
      return const TransactionListScreen();
    }

    return const LoginScreen();
  }
}
