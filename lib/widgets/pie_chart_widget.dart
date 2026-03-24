import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/wallet.dart';

class PieChartWidget extends StatelessWidget {
  const PieChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    final expenseData = provider.expenseByWallet();
    final wallets = provider.wallets;

    if (expenseData.isEmpty) {
      return const Center(child: Text('No expenses yet.'));
    }

    // Danh sách màu
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.pink,
      Colors.cyan,
    ];

    final totalExpense = expenseData.values.fold<double>(
      0,
      (sum, e) => sum + e,
    );

    // Tạo section với badge để hiển thị số tiền ra ngoài
    final sections = expenseData.entries.map((entry) {
      final wallet = wallets.firstWhere(
        (w) => w.id == entry.key,
        orElse: () => Wallet(
          id: entry.key,
          name: 'Unknown',
          iconCode: 0,
          budget: 0,
          balance: 0,
        ),
      );
      final value = entry.value;
      final color = colors[entry.key % colors.length];

      final percent = (value / totalExpense * 100).toStringAsFixed(1);

      return PieChartSectionData(
        value: value,
        color: color,
        radius: 60,
        title: "${wallet.name}\n$percent%",
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _buildBadge(value),
        badgePositionPercentageOffset: 1.2, // badge ra ngoài phần tròn
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        borderData: FlBorderData(show: false),
      ),
    );
  }

  /// Widget hiển thị số tiền ra ngoài PieChart
  Widget _buildBadge(double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "${amount.toStringAsFixed(0)} VND",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
