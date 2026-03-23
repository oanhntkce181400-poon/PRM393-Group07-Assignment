import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/providers/debt_loan_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DebtLoanOverviewScreen extends StatefulWidget {
  const DebtLoanOverviewScreen({super.key});

  @override
  State<DebtLoanOverviewScreen> createState() => _DebtLoanOverviewScreenState();
}

class _DebtLoanOverviewScreenState extends State<DebtLoanOverviewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  double _sumAmount(List<Debt> debts) {
    return debts.fold(0, (sum, item) => sum + item.amount);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtLoanProvider>().loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      appBar: AppBar(title: const Text('Danh sách nợ & vay')),
      body: Consumer<DebtLoanProvider>(
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
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: provider.refreshData,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final lendTotal = _sumAmount(provider.lendDebts);
          final borrowTotal = _sumAmount(provider.borrowDebts);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _OverviewSummaryCard(
                        title: 'Bạn cho mượn',
                        value:
                            '${NumberFormat.decimalPattern('vi_VN').format(lendTotal)} VND',
                        color: const Color(0xFF0EA5A4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OverviewSummaryCard(
                        title: 'Bạn đi vay',
                        value:
                            '${NumberFormat.decimalPattern('vi_VN').format(borrowTotal)} VND',
                        color: const Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorPadding: const EdgeInsets.all(6),
                    labelColor: const Color(0xFF0F766E),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    tabs: const [
                      Tab(text: 'Tiền cho mượn'),
                      Tab(text: 'Tiền đi vay'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DebtListView(
                      debts: provider.lendDebts,
                      emptyText: 'Bạn chưa có khoản cho mượn nào.',
                    ),
                    _DebtListView(
                      debts: provider.borrowDebts,
                      emptyText: 'Bạn chưa có khoản đi vay nào.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DebtListView extends StatelessWidget {
  const _DebtListView({required this.debts, required this.emptyText});

  final List<Debt> debts;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: debts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final debt = debts[index];
        final dueDate = DateTime.tryParse(debt.dueDate);
        final formattedDueDate = dueDate == null
            ? debt.dueDate
            : DateFormat('dd/MM/yyyy').format(dueDate);

        final isPaid = debt.status == 1;
        final textStyle = TextStyle(
          decoration: isPaid ? TextDecoration.lineThrough : TextDecoration.none,
          color: isPaid ? Colors.grey.shade600 : const Color(0xFF0F172A),
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPaid
                  ? Colors.grey.withValues(alpha: 0.25)
                  : const Color(0xFF99F6E4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      debt.partnerName,
                      style: textStyle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? Colors.grey.withValues(alpha: 0.12)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isPaid
                            ? Colors.grey.shade700
                            : const Color(0xFF0369A1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Số tiền: ${NumberFormat.decimalPattern('vi_VN').format(debt.amount)} VND',
                style: textStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hẹn ngày trả: $formattedDueDate',
                style: textStyle.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.task_alt_outlined,
                    size: 18,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Đánh dấu khi khoản nợ đã hoàn tất',
                      style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                    ),
                  ),
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: isPaid,
                      activeColor: const Color(0xFF0F766E),
                      onChanged: (value) async {
                        if (debt.id == null || value == null) {
                          return;
                        }
                        await context.read<DebtLoanProvider>().markDebtPaid(
                          debt.id!,
                          value,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewSummaryCard extends StatelessWidget {
  const _OverviewSummaryCard({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
