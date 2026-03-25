import 'dart:ui';

import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/providers/auth_provider.dart';
import 'package:expense_tracker/screens/add_edit_transaction_screen.dart';
import 'package:expense_tracker/screens/debt_loan_management_screen.dart';
import 'package:expense_tracker/screens/envelope_managemet_screen.dart';
import 'package:expense_tracker/screens/goal_list_screen.dart';
import 'package:expense_tracker/screens/notifications_screen.dart';
import 'package:expense_tracker/screens/transaction_detail_screen.dart';
import 'package:expense_tracker/screens/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  Future<void> _openFeatureScreen(BuildContext context, String value) async {
    final notificationProvider = context.read<NotificationProvider>();

    Widget screen;
    if (value == 'debt_manage') {
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
    if (hour < 12) return 'Chào buổi sáng, Oanh!';
    if (hour < 18) return 'Chào buổi chiều, Oanh!';
    return 'Chào buổi tối, Oanh!';
  }

  String _buildMoodLine(double totalBalance) {
    if (totalBalance < 500000) return 'Sắp hết tiền rồi nha!';
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

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                stretch: true,
                expandedHeight: 230,
                backgroundColor: Colors.white.withAlpha(184),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                actions: [
                  // Nút Thông báo
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, child) {
                        final unread = notificationProvider.unreadCount;
                        return IconButton(
                          tooltip: 'Thông báo',
                          onPressed: () =>
                              _openFeatureScreen(context, 'notifications'),
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withAlpha(36),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 18,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: -6,
                                  top: -5,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.4,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        unread > 99 ? '99+' : '$unread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: GestureDetector(
                      onTap: () async {
                        // Hiển thị dialog xác nhận logout
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Đăng xuất?'),
                            content: const Text(
                              'Bạn có chắc chắn muốn đăng xuất không?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Đăng xuất'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          // Gọi hàm logout từ AuthProvider
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login', // route đến LoginScreen
                              (route) => false,
                            );
                          }
                        }
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF0F766E).withAlpha(41),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: Color(0xFF0F766E),
                        ),
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
                                Colors.white.withAlpha(209),
                                const Color(0xFFD1FAE5).withAlpha(148),
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
                                    ).withAlpha(33),
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
                                    ).withAlpha(28),
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
                                        color: Colors.white.withAlpha(127),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withAlpha(166),
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
                                                Text(
                                                  NumberFormat.currency(
                                                    locale: 'vi_VN',
                                                    symbol: 'Tổng số dư: ',
                                                  ).format(totalBalance),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF0F766E),
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

              // Phần Slivers: summary pill, feature actions, transaction list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryPill(
                          title: 'Thu nhập',
                          value: NumberFormat.compactCurrency(
                            locale: 'vi_VN',
                            symbol: 'VND ',
                          ).format(incomeTotal),
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryPill(
                          title: 'Chi tiêu',
                          value: NumberFormat.compactCurrency(
                            locale: 'vi_VN',
                            symbol: 'VND ',
                          ).format(expenseTotal),
                          color: Colors.red,
                        ),
                      ),
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
                      Row(
                        children: [
                          Expanded(
                            child: _FeatureQuickAction(
                              title: 'Nợ & vay',
                              subtitle: 'Xem / thêm / sửa / xóa',
                              icon: Icons.account_balance_wallet_outlined,
                              color: const Color(0xFF0EA5A4),
                              onTap: () =>
                                  _openFeatureScreen(context, 'debt_manage'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _FeatureQuickAction(
                              title: 'Quỹ tiết kiệm',
                              subtitle: 'Xem mục tiêu',
                              icon: Icons.savings_outlined,
                              color: const Color(0xFFF59E0B),
                              onTap: () => _openFeatureScreen(context, 'goal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FeatureQuickAction(
                              title: 'Túi tiền',
                              subtitle: 'Quản lý túi tiền',
                              icon: Icons.account_balance_wallet_rounded,
                              color: const Color(0xFF2563EB),
                              onTap: () => _openFeatureScreen(
                                context,
                                'envelope_manage',
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
                          ? Icons.arrow_downward
                          : Icons.arrow_upward;
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
                                  backgroundColor: color.withAlpha(31),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(184),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title: $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureQuickAction extends StatelessWidget {
  const _FeatureQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(56)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withAlpha(41),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
