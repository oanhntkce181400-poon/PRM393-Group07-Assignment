import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// PROVIDERS
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/debt_loan_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/envelope_provider.dart';

/// SCREENS / WIDGETS
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// ✅ FIX SQFLITE DESKTOP
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// ✅ AUTH
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),

        /// ✅ TRANSACTION
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..loadInitialData(),
        ),

        /// ✅ GOAL
        ChangeNotifierProvider(
          create: (_) => GoalProvider()..loadInitialData(),
        ),

        /// ✅ DEBT / LOAN
        ChangeNotifierProvider(
          create: (_) => DebtLoanProvider()..loadInitialData(),
        ),

        /// ✅ NOTIFICATION
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..loadInitialData(),
        ),

        /// ✅ ENVELOPE
        ChangeNotifierProvider(create: (_) => EnvelopeProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quản lý chi tiêu',

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
          useMaterial3: true,

          scaffoldBackgroundColor: const Color(0xFFF7F9FA),

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF0F172A),
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        /// ✅ QUAN TRỌNG
        /// vào login trước
        home: const AuthGate(),
      ),
    );
  }
}
