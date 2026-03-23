import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:expense_tracker/screens/add_edit_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.heroTag,
  });

  final int transactionId;
  final String? heroTag;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Future<Map<String, dynamic>?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<Map<String, dynamic>?> _loadDetail() {
    return context.read<TransactionProvider>().getTransactionDetail(
      widget.transactionId,
    );
  }

  Future<void> _confirmDelete(int transactionId) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa giao dịch?'),
            content: const Text('Giao dịch này sẽ bị xóa vĩnh viễn.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !mounted) {
      return;
    }

    await context.read<TransactionProvider>().deleteTransaction(transactionId);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa giao dịch.')));
    Navigator.pop(context, true);
  }

  List<Color> _buildHeaderGradient(bool isExpense) {
    if (isExpense) {
      return const [Color(0xFFDC2626), Color(0xFFF97316)];
    }
    return const [Color(0xFF059669), Color(0xFF22C55E)];
  }

  String _formatAmount(double amount, {required bool isExpense}) {
    final sign = isExpense ? '-' : '+';
    final value = NumberFormat.decimalPattern('vi_VN').format(amount);
    return '$sign $value VNĐ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FutureBuilder<Map<String, dynamic>?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          final detail = snapshot.data;
          if (detail == null) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton(
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddEditTransactionScreen(existingTransaction: detail),
                ),
              );

              if (changed == true && context.mounted) {
                setState(() {
                  _detailFuture = _loadDetail();
                });
              }
            },
            child: const Icon(Icons.edit_rounded),
          );
        },
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Lỗi tải chi tiết: ${snapshot.error}'),
              ),
            );
          }

          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('Không tìm thấy giao dịch.'));
          }

          final amount = (detail['amount'] as num).toDouble();
          final transactionType = detail['transactionType'] as String;
          final isExpense = transactionType == 'EXPENSE';
          final headerHeight = (MediaQuery.of(context).size.height * 0.33)
              .clamp(250.0, 350.0);
          final walletIconCode = (detail['walletIconCode'] as num?)?.toInt();
          final formattedDate =
              DateTime.tryParse(detail['date'] as String) == null
              ? '-'
              : DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(DateTime.parse(detail['date'] as String));

          final walletIcon = Icon(
            walletIconCode != null
                ? IconData(walletIconCode, fontFamily: 'MaterialIcons')
                : Icons.account_balance_wallet_rounded,
            size: 34,
            color: Colors.white,
          );

          return Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Container(
                      height: headerHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _buildHeaderGradient(isExpense),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 22),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const _BouncyBackButton(),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: const Text(
                                          'Chi tiết giao dịch',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _confirmDelete(
                                      (detail['id'] as num).toInt(),
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Spacer(),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatAmount(amount, isExpense: isExpense),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                detail['walletName'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: Container(color: const Color(0xFFF1F5F9))),
                  ],
                ),
              ),
              Positioned(
                top: headerHeight - 48,
                left: 0,
                right: 0,
                bottom: 0,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 110),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                        bottom: Radius.circular(26),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 70),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
                          child: Column(
                            children: [
                              _InfoLine(
                                label: 'Mã giao dịch',
                                value: '${detail['id']}',
                              ),
                              const Divider(height: 22),
                              _InfoLine(
                                label: 'Ngày giờ',
                                value: formattedDate,
                              ),
                              const Divider(height: 22),
                              _InfoLine(
                                label: 'Loại giao dịch',
                                value: isExpense ? 'Chi tiêu' : 'Thu nhập',
                              ),
                              const Divider(height: 22),
                              _InfoLine(
                                label: 'Ghi chú',
                                value:
                                    ((detail['note'] as String?) ?? '').isEmpty
                                    ? '-'
                                    : detail['note'] as String,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () => _confirmDelete(
                                    (detail['id'] as num).toInt(),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Xóa giao dịch'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                    side: BorderSide(
                                      color: Colors.red.shade200,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: headerHeight - 38,
                left: 0,
                right: 0,
                child: Center(
                  child: Hero(
                    tag: widget.heroTag ?? 'tx_wallet_${widget.transactionId}',
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      child: walletIcon,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _BouncyBackButton extends StatefulWidget {
  const _BouncyBackButton();

  @override
  State<_BouncyBackButton> createState() => _BouncyBackButtonState();
}

class _BouncyBackButtonState extends State<_BouncyBackButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.86),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) {
        setState(() => _scale = 1);
        Navigator.maybePop(context);
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: CircleAvatar(
          radius: 19,
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
