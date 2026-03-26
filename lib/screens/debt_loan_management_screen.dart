import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/providers/debt_loan_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DebtLoanManagementScreen extends StatefulWidget {
  const DebtLoanManagementScreen({super.key});

  @override
  State<DebtLoanManagementScreen> createState() =>
      _DebtLoanManagementScreenState();
}

class _DebtLoanManagementScreenState extends State<DebtLoanManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String _tabTitle() {
    return _tabController.index == 0 ? 'khoản cho mượn' : 'khoản đi vay';
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

  Future<void> _openDebtForm({Debt? existing, required String debtType}) async {
    final provider = context.read<DebtLoanProvider>();
    final submittedDebt = await showDialog<Debt>(
      context: context,
      builder: (dialogContext) =>
          _DebtFormDialog(existing: existing, debtType: debtType),
    );

    try {
      if (submittedDebt != null) {
        if (existing == null) {
          await provider.addDebt(submittedDebt);
        } else {
          await provider.updateDebt(submittedDebt);
        }

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu khoản nợ.')));
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lưu khoản nợ thất bại: $e')));
    }
  }

  Future<void> _deleteDebt(Debt debt) async {
    if (debt.id == null) {
      return;
    }

    final provider = context.read<DebtLoanProvider>();

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa khoản nợ?'),
            content: const Text('Hành động này không thể hoàn tác.'),
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

    if (!shouldDelete) {
      return;
    }

    await provider.deleteDebt(debt.id!);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa khoản nợ.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('Quản lý nợ / vay'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.edit_note_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final debtType = _tabController.index == 0 ? 'LEND' : 'BORROW';
          _openDebtForm(debtType: debtType);
        },
        icon: const Icon(Icons.add),
        label: Text('Thêm ${_tabTitle()}'),
      ),
      body: Consumer<DebtLoanProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  provider.errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF075985)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mẹo: Bạn có thể thêm mới, sửa nhanh hoặc xóa trực tiếp trong danh sách.',
                          style: TextStyle(
                            color: Color(0xFF075985),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    onTap: (_) => setState(() {}),
                    tabs: const [
                      Tab(text: 'Tiền cho mượn'),
                      Tab(text: 'Tiền đi vay'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ManageDebtList(
                      debts: provider.lendDebts,
                      statusText: (isPaid) => isPaid
                          ? 'Đã thu hồi khoản cho mượn'
                          : 'Chưa thu hồi khoản cho mượn',
                      onTogglePaid: (debt, isPaid) =>
                          provider.markDebtPaid(debt.id!, isPaid),
                      onEdit: (debt) =>
                          _openDebtForm(existing: debt, debtType: 'LEND'),
                      onDelete: _deleteDebt,
                    ),
                    _ManageDebtList(
                      debts: provider.borrowDebts,
                      statusText: (isPaid) =>
                          isPaid ? 'Đã trả nợ khi vay' : 'Chưa trả nợ khi vay',
                      onTogglePaid: (debt, isPaid) =>
                          provider.markDebtPaid(debt.id!, isPaid),
                      onEdit: (debt) =>
                          _openDebtForm(existing: debt, debtType: 'BORROW'),
                      onDelete: _deleteDebt,
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

class _DebtFormDialog extends StatefulWidget {
  const _DebtFormDialog({required this.debtType, this.existing});

  final String debtType;
  final Debt? existing;

  @override
  State<_DebtFormDialog> createState() => _DebtFormDialogState();
}

class _DebtFormDialogState extends State<_DebtFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  late DateTime _selectedDate;

  bool get _isLend => widget.debtType == 'LEND';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existing?.partnerName ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existing == null
          ? ''
          : NumberFormat.decimalPattern(
              'vi_VN',
            ).format(widget.existing!.amount.round()),
    );
    _selectedDate =
        DateTime.tryParse(widget.existing?.dueDate ?? '') ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }
    return double.tryParse(digitsOnly);
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final amount = _parseAmount(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final debt = Debt(
      id: widget.existing?.id,
      partnerName: _nameController.text.trim(),
      debtType: widget.debtType,
      amount: amount,
      dueDate: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ).toIso8601String(),
      status: widget.existing?.status ?? 0,
    );

    if (mounted) {
      Navigator.pop(context, debt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formTitle = widget.existing == null
        ? (_isLend ? 'Thêm tiền cho mượn' : 'Thêm tiền đi vay')
        : (_isLend ? 'Sửa khoản cho mượn' : 'Sửa khoản đi vay');
    final typeLabel = _isLend ? 'Loại: Tiền cho mượn' : 'Loại: Tiền đi vay';
    final typeHint = _isLend
        ? 'Bạn đang nhập khoản người khác nợ bạn.'
        : 'Bạn đang nhập khoản bạn nợ người khác.';
    final partnerLabel = _isLend
        ? 'Tên người mượn tiền'
        : 'Tên người cho bạn vay';
    final amountLabel = _isLend
        ? 'Số tiền cho mượn (VND)'
        : 'Số tiền đi vay (VND)';

    return AlertDialog(
      title: Text(formTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _isLend
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _isLend
                            ? const Color(0xFF166534)
                            : const Color(0xFF9A3412),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isLend
                            ? const Color(0xFF166534)
                            : const Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: partnerLabel),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: amountLabel,
                  hintText: 'Ví dụ: 2.000.000',
                ),
                validator: (value) {
                  final amount = _parseAmount(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Vui lòng nhập số tiền hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_isLend ? 'Hẹn người đó trả' : 'Hẹn bạn trả'}: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Chọn ngày'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isLend ? 'Lưu khoản cho mượn' : 'Lưu khoản đi vay'),
        ),
      ],
    );
  }
}

class _ManageDebtList extends StatelessWidget {
  const _ManageDebtList({
    required this.debts,
    required this.statusText,
    required this.onTogglePaid,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Debt> debts;
  final String Function(bool isPaid) statusText;
  final Future<void> Function(Debt debt, bool isPaid) onTogglePaid;
  final ValueChanged<Debt> onEdit;
  final ValueChanged<Debt> onDelete;

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có dữ liệu. Nhấn nút thêm để tạo mới.',
          style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
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

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.grey.withValues(alpha: 0.14)
                      : const Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaid ? Icons.check_rounded : Icons.schedule,
                  color: isPaid
                      ? Colors.grey.shade700
                      : const Color(0xFF047857),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.partnerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Số tiền: ${NumberFormat.decimalPattern('vi_VN').format(debt.amount)} VND',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hẹn trả: $formattedDueDate',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 1.05,
                          child: Checkbox(
                            value: isPaid,
                            activeColor: const Color(0xFF0F766E),
                            onChanged: debt.id == null
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    onTogglePaid(debt, value);
                                  },
                          ),
                        ),
                        Expanded(
                          child: Text(
                            statusText(isPaid),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isPaid
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF9A3412),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Sửa',
                    onPressed: () => onEdit(debt),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  const SizedBox(height: 6),
                  IconButton.filledTonal(
                    tooltip: 'Xóa',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                    ),
                    onPressed: () => onDelete(debt),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
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
