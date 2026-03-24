import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/screens/add_edit_transaction_screen.dart';
import 'package:expense_tracker/screens/transaction_detail_screen.dart';
import 'package:expense_tracker/screens/statistics_screen.dart'; // ⭐ NEW
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transaction List',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        centerTitle: true,
      ),

      /// ================= BODY =================
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: provider.refreshData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.transactions.isEmpty) {
            return const Center(
              child: Text('No transactions yet. Tap + to add one.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: provider.transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = provider.transactions[index];

              final txId = (tx['id'] as num).toInt();
              final transactionType = tx['transactionType'] as String;
              final amount = (tx['amount'] as num).toDouble();
              final walletName = tx['walletName'] as String;
              final note = (tx['note'] as String?) ?? '';

              final parsedDate = DateTime.tryParse(tx['date'] as String);
              final formattedDate = parsedDate == null
                  ? '-'
                  : DateFormat('dd/MM/yyyy').format(parsedDate);

              final isExpense = transactionType == 'EXPENSE';
              final color = isExpense ? Colors.red : Colors.green;

              final icon = isExpense
                  ? Icons.arrow_downward
                  : Icons.arrow_upward;

              final signedAmount = isExpense
                  ? '-${NumberFormat.currency(locale: 'vi_VN', symbol: 'VND ').format(amount)}'
                  : '+${NumberFormat.currency(locale: 'vi_VN', symbol: 'VND ').format(amount)}';

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 220 + (index * 35)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 18),
                      child: child,
                    ),
                  );
                },
                child: Dismissible(
                  key: ValueKey(txId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete transaction?'),
                            content: const Text(
                              'This action will remove the transaction and recalculate wallet balance.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    await context.read<TransactionProvider>().deleteTransaction(
                      txId,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted.')),
                      );
                    }
                  },
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(
                        note.isEmpty ? 'No note' : note,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('$walletName • $formattedDate'),
                      ),
                      trailing: Text(
                        signedAmount,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TransactionDetailScreen(transactionId: txId),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      /// ================= FLOATING BUTTONS =================
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 📊 STATISTICS BUTTON (NEW)
          FloatingActionButton(
            heroTag: "stats_btn",
            mini: true,
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
            child: const Icon(Icons.pie_chart),
          ),

          const SizedBox(height: 12),

          /// ➕ ADD TRANSACTION (OLD BUTTON)
          FloatingActionButton(
            heroTag: "add_btn",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditTransactionScreen(),
                ),
              );
            },
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
