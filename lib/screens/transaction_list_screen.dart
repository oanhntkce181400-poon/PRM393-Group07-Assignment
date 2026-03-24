import 'dart:ui';

import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/screens/add_edit_transaction_screen.dart';
import 'package:expense_tracker/screens/debt_loan_management_screen.dart';
import 'package:expense_tracker/screens/debt_loan_overview_screen.dart';
import 'package:expense_tracker/screens/envelope_managemet_screen.dart';
import 'package:expense_tracker/screens/goal_list_screen.dart';
import 'package:expense_tracker/models/feature_action_item.dart';
import 'package:expense_tracker/models/summary_item.dart';
import 'package:expense_tracker/screens/notifications_screen.dart';
import 'package:expense_tracker/screens/feature_quick_action.dart';
import 'package:expense_tracker/screens/summary_pill.dart';
import 'package:expense_tracker/screens/transaction_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  Future<void> _openFeatureScreen(BuildContext context, String value) async {
    final notificationProvider = context.read<NotificationProvider>();

    Widget screen;
    if (value == 'debt_overview') {
      screen = const DebtLoanOverviewScreen();
    } else if (value == 'debt_manage') {
      screen = const DebtLoanManagementScreen();
    } else if (value == 'goal') {
      screen = const GoalListScreen();
    } else if (value == 'envelope_manage') {
      screen = const EnvelopeManagementScreen();
    } else {
      screen = const NotificationsScreen();
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    await notificationProvider.refreshData();
  }

  String _buildGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng, Oanh!';
    }
    if (hour < 18) {
      return 'Chào buổi chiều, Oanh!';
    }
    return 'Chào buổi tối, Oanh!';
  }

  String _buildMoodLine(double totalBalance) {
    if (totalBalance < 500000) {
      return 'Sắp hết tiền rồi nha!';
    }
    return 'Giúp bạn kiểm soát từng đồng tiền.';
  }

  String _formatSignedAmount(double amount, {required bool isExpense}) {
    final sign = isExpense ? '-' : '+';
    final number = NumberFormat.decimalPattern('vi_VN').format(amount);
    return '$sign$number VND';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
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
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalBalance = provider.wallets.fold<double>(
            0,
            (sum, wallet) => sum + wallet.balance,
          );

          double expenseTotal = 0;
          double incomeTotal = 0;
          for (final tx in provider.transactions) {
            final amount = (tx['amount'] as num).toDouble();
            if ((tx['transactionType'] as String) == 'EXPENSE') {
              expenseTotal += amount;
            } else {
              incomeTotal += amount;
            }
          }

          final summaryItems = [
            SummaryItem(
              title: 'Thu nhập',
              value:
                  '${NumberFormat.decimalPattern('vi_VN').format(incomeTotal)} VND',
              color: Colors.green,
            ),
            SummaryItem(
              title: 'Chi tiêu',
              value:
                  '${NumberFormat.decimalPattern('vi_VN').format(expenseTotal)} VND',
              color: Colors.red,
            ),
          ];

          final featureActions = [
            const FeatureActionItem(
              title: 'Nợ & vay',
              subtitle: 'Xem danh sách',
              icon: Icons.account_balance_wallet_outlined,
              color: Color(0xFF0EA5A4),
              actionKey: 'debt_overview',
            ),
            const FeatureActionItem(
              title: 'Quản lý nợ',
              subtitle: 'Thêm / sửa / xóa',
              icon: Icons.edit_note_rounded,
              color: Color(0xFF22C55E),
              actionKey: 'debt_manage',
            ),
            const FeatureActionItem(
              title: 'Quỹ tiết kiệm',
              subtitle: 'Xem mục tiêu',
              icon: Icons.savings_outlined,
              color: Color(0xFFF59E0B),
              actionKey: 'goal',
            ),
            const FeatureActionItem(
              title: 'Túi tiền',
              subtitle: 'Quản lý túi tiền',
              icon: Icons.account_balance_wallet_rounded,
              color: Color(0xFF2563EB),
              actionKey: 'envelope_manage',
            ),
          ];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                stretch: true,
                expandedHeight: 230,
                backgroundColor: Colors.white.withValues(alpha: 0.72),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(
                        0xFF0F766E,
                      ).withValues(alpha: 0.16),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
                title: Text(
                  'Danh sách giao dịch',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    const minHeight = kToolbarHeight;
                    const maxHeight = 230.0;
                    final progress =
                        ((constraints.biggest.height - minHeight) /
                                (maxHeight - minHeight))
                            .clamp(0.0, 1.0)
                            .toDouble();

                    return ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.82),
                                const Color(0xFFD1FAE5).withValues(alpha: 0.58),
                              ],
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned(
                                right: -22,
                                top: 8 + (1 - progress) * 18,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF34D399,
                                    ).withValues(alpha: 0.13),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -34,
                                bottom: -40 + (1 - progress) * 25,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF14B8A6,
                                    ).withValues(alpha: 0.11),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 14,
                                child: Opacity(
                                  opacity: progress,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - progress) * 14),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.65,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _buildGreeting(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _buildMoodLine(totalBalance),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFF334155,
                                                        ),
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                RichText(
                                                  text: TextSpan(
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF0F766E),
                                                    ),
                                                    children: [
                                                      const TextSpan(
                                                        text: 'Tổng số dư: ',
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            '${NumberFormat.decimalPattern('vi_VN').format(totalBalance)} ₫',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 62,
                                            height: 62,
                                            child: Lottie.network(
                                              'https://assets10.lottiefiles.com/packages/lf20_jcikwtux.json',
                                              repeat: true,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.monetization_on,
                                                    color: Color(0xFF0F766E),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      Expanded(child: SummaryPill(item: summaryItems[0])),
                      const SizedBox(width: 10),
                      Expanded(child: SummaryPill(item: summaryItems[1])),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiện ích nhanh',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                      ),
                      const SizedBox(height: 10),

                      // Hàng 1: 2 nút cũ
                      Row(
                        children: [
                          Expanded(
                            child: FeatureQuickAction(
                              item: featureActions[0],
                              onTap: () => _openFeatureScreen(
                                context,
                                featureActions[0].actionKey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FeatureQuickAction(
                              item: featureActions[1],
                              onTap: () => _openFeatureScreen(
                                context,
                                featureActions[1].actionKey,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FeatureQuickAction(
                              item: featureActions[2],
                              onTap: () => _openFeatureScreen(
                                context,
                                featureActions[2].actionKey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FeatureQuickAction(
                              item: featureActions[3],
                              onTap: () => _openFeatureScreen(
                                context,
                                featureActions[3].actionKey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.transactions.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Chưa có giao dịch nào. Nhấn + để thêm mới.'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 90),
                  sliver: SliverList.separated(
                    itemCount: provider.transactions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = provider.transactions[index];
                      final txId = (tx['id'] as num).toInt();
                      final transactionType = tx['transactionType'] as String;
                      final amount = (tx['amount'] as num).toDouble();
                      final walletName = tx['walletName'] as String;
                      final note = (tx['note'] as String?) ?? '';
                      final parsedDate = DateTime.tryParse(
                        tx['date'] as String,
                      );
                      final formattedDate = parsedDate == null
                          ? '-'
                          : DateFormat('dd/MM/yyyy').format(parsedDate);

                      final isExpense = transactionType == 'EXPENSE';
                      final color = isExpense ? Colors.red : Colors.green;
                      final icon = isExpense
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded;
                      final signedAmount = _formatSignedAmount(
                        amount,
                        isExpense: isExpense,
                      );

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 220 + (index * 35)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0).toDouble(),
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
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Xóa giao dịch?'),
                                    content: const Text(
                                      'Hành động này sẽ xóa giao dịch và cập nhật lại số dư ví.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const Text('Hủy'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) async {
                            await context
                                .read<TransactionProvider>()
                                .deleteTransaction(txId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã xóa giao dịch.'),
                                ),
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
                              leading: Hero(
                                tag: 'tx_wallet_$txId',
                                child: CircleAvatar(
                                  backgroundColor: color.withValues(
                                    alpha: 0.12,
                                  ),
                                  child: Icon(icon, color: color),
                                ),
                              ),
                              title: Text(
                                note.isEmpty ? 'Không có ghi chú' : note,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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
                                    builder: (_) => TransactionDetailScreen(
                                      transactionId: txId,
                                      heroTag: 'tx_wallet_$txId',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
