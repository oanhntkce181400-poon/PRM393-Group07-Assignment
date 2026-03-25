import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/pie_chart_widget.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          /// TOTAL BALANCE
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Total Balance", style: TextStyle(fontSize: 18)),
                  Text(
                    "${provider.totalBalance1().toStringAsFixed(0)} VND",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// PIE CHART
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: PieChartWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
