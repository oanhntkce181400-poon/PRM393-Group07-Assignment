import 'package:expense_tracker/providers/debt_loan_provider.dart';
import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/screens/transaction_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..loadInitialData(),
        ),
        ChangeNotifierProvider(create: (_) => DebtLoanProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..loadInitialData(),
        ),
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
              letterSpacing: 0.4,
            ),
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF7DD3C7),
            foregroundColor: Color(0xFF083344),
            elevation: 8,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        home: const TransactionListScreen(),
      ),
    );
  }
}
