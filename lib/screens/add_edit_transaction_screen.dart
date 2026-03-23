import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  const AddEditTransactionScreen({super.key, this.existingTransaction});

  final Map<String, dynamic>? existingTransaction;

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _walletId;
  String _transactionType = 'EXPENSE';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  bool get _isEditMode => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    _prefillFormIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // [DONG_BO_DANH_SACH_VI] Luôn lấy danh sách ví mới nhất khi mở màn hình.
      context.read<TransactionProvider>().refreshWalletsOnly();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _prefillFormIfNeeded() {
    final existing = widget.existingTransaction;
    if (existing == null) {
      return;
    }

    _walletId = (existing['walletId'] as num).toInt();
    _transactionType = (existing['transactionType'] as String?) ?? 'EXPENSE';
    _amountController.text = (existing['amount'] as num).toString();
    _noteController.text = (existing['note'] as String?) ?? '';

    final parsedDate = DateTime.tryParse(existing['date'] as String);
    if (parsedDate != null) {
      _selectedDate = parsedDate;
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  // [NHAP_GIAO_DICH] Thu thập input và lưu giao dịch mới/chỉnh sửa.
  Future<void> _submit() async {
    final provider = context.read<TransactionProvider>();

    // [KIEM_TRA_DAU_VAO] Bắt buộc chọn ví.
    if (_walletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ví.')));
      return;
    }

    final rawAmount = _amountController.text.trim();
    // [KIEM_TRA_DAU_VAO] Bắt buộc nhập số tiền.
    if (rawAmount.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền.')));
      return;
    }

    final parsedAmount = double.tryParse(rawAmount);
    // [KIEM_TRA_DAU_VAO] Số tiền phải là số dương.
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Số tiền phải lớn hơn 0.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // [TAO_MODEL] Đóng gói dữ liệu form thành model Transaction.
      final tx = Transaction(
        id: _isEditMode
            ? (widget.existingTransaction!['id'] as num).toInt()
            : null,
        walletId: _walletId!,
        amount: parsedAmount,
        transactionType: _transactionType,
        date: _selectedDate.toIso8601String(),
        note: _noteController.text.trim(),
      );

      if (_isEditMode) {
        // [LUU_DB] Chế độ sửa giao dịch.
        await provider.updateTransaction(tx);
      } else {
        // [LUU_DB] Chế độ thêm giao dịch mới.
        await provider.addTransaction(tx);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lưu giao dịch thất bại: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isEditMode) {
      return;
    }

    final transactionId = (widget.existingTransaction!['id'] as num).toInt();
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa giao dịch?'),
            content: const Text('Bạn sẽ không thể hoàn tác thao tác này.'),
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

    Navigator.pop(context, true);
  }

  InputDecoration _softDecoration({
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.teal.shade300, width: 1.2),
      ),
    );
  }

  String _formattedAmount() {
    final raw = _amountController.text.trim();
    final amount = double.tryParse(raw) ?? 0;
    final sign = _transactionType == 'EXPENSE' ? '-' : '+';
    return '$sign ${NumberFormat.decimalPattern('vi_VN').format(amount)} VNĐ';
  }

  List<Color> _topGradient() {
    if (_transactionType == 'EXPENSE') {
      return const [Color(0xFFDC2626), Color(0xFFF97316)];
    }
    return const [Color(0xFF059669), Color(0xFF22C55E)];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = (screenHeight * 0.32).clamp(250.0, 340.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width - 32,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: _topGradient()),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _isSubmitting ? null : _submit,
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditMode ? 'Cập nhật giao dịch' : 'Lưu giao dịch',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: provider.wallets.isEmpty && !provider.isLoading
          ? const Center(child: Text('Chưa có ví nào. Vui lòng tạo ví trước.'))
          : Stack(
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
                            colors: _topGradient(),
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
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
                                          child: Text(
                                            _isEditMode
                                                ? 'Chỉnh sửa giao dịch'
                                                : 'Thêm giao dịch mới',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_isEditMode)
                                      IconButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : _confirmDelete,
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                        ),
                                      ),
                                    if (!_isEditMode) const SizedBox(width: 48),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.9,
                                        end: 1,
                                      ).animate(animation),
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _formattedAmount(),
                                    key: ValueKey(
                                      '${_transactionType}_${_amountController.text}',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 210,
                                  child: TextFormField(
                                    controller: _amountController,
                                    textAlign: TextAlign.center,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Nhập số tiền',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(color: const Color(0xFFF1F5F9)),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: headerHeight - 16,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                            bottom: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Loại giao dịch',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Chi tiêu'),
                                    selected: _transactionType == 'EXPENSE',
                                    onSelected: (_) {
                                      setState(() {
                                        _transactionType = 'EXPENSE';
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Thu nhập'),
                                    selected: _transactionType == 'INCOME',
                                    onSelected: (_) {
                                      setState(() {
                                        _transactionType = 'INCOME';
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Chọn ví',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 86,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: provider.wallets.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final wallet = provider.wallets[index];
                                    final isSelected = _walletId == wallet.id;
                                    final iconData = IconData(
                                      wallet.iconCode,
                                      fontFamily: 'MaterialIcons',
                                    );

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        setState(() {
                                          _walletId = wallet.id;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        width: 102,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(
                                                  0xFF0F766E,
                                                ).withValues(alpha: 0.14)
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF0F766E)
                                                : Colors.transparent,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              iconData,
                                              color: isSelected
                                                  ? const Color(0xFF0F766E)
                                                  : const Color(0xFF475569),
                                            ),
                                            const SizedBox(height: 7),
                                            Text(
                                              wallet.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? const Color(0xFF0F766E)
                                                    : const Color(0xFF334155),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(16),
                                child: InputDecorator(
                                  decoration: _softDecoration(
                                    label: 'Ngày',
                                    prefixIcon: Icons.calendar_today,
                                    suffixIcon: const Icon(
                                      Icons.keyboard_arrow_down,
                                    ),
                                  ),
                                  child: Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_selectedDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _noteController,
                                maxLines: 3,
                                decoration: _softDecoration(
                                  label: 'Ghi chú',
                                  prefixIcon: Icons.edit_note,
                                ),
                              ),
                              if (_isEditMode) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: _isSubmitting
                                        ? null
                                        : _confirmDelete,
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
          backgroundColor: Colors.white.withValues(alpha: 0.28),
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
