import 'package:expense_tracker/constants/wallet_icons.dart';
import 'package:expense_tracker/providers/envelope_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EnvelopeDetailEditScreen extends StatefulWidget {
  const EnvelopeDetailEditScreen({super.key, required this.walletId});
  final int walletId;

  @override
  State<EnvelopeDetailEditScreen> createState() =>
      _EnvelopeDetailEditScreenState();
}

class _EnvelopeDetailEditScreenState extends State<EnvelopeDetailEditScreen> {
  int _codeByLabel(String label) {
    return kWalletIconOptions.firstWhere((item) => item.label == label).code;
  }

  bool _isKnownCode(int? code) {
    if (code == null) return false;
    for (final item in kWalletIconOptions) {
      if (item.code == code) {
        return true;
      }
    }
    return false;
  }

  int _guessCodeByWalletName(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('an') || lower.contains('uong') || lower.contains('food')) {
      return _codeByLabel('Ăn uống');
    }
    if (lower.contains('tro') || lower.contains('nha')) {
      return _codeByLabel('Nhà ở / Trọ');
    }
    if (lower.contains('di') || lower.contains('xe') || lower.contains('xang')) {
      return _codeByLabel('Đi lại');
    }
    if (lower.contains('mua') || lower.contains('shop')) {
      return _codeByLabel('Mua sắm');
    }
    if (lower.contains('the thao') || lower.contains('sport')) {
      return _codeByLabel('Thể thao');
    }
    if (lower.contains('gym') || lower.contains('tap')) {
      return _codeByLabel('Gym');
    }
    if (lower.contains('hoc') || lower.contains('sach')) {
      return _codeByLabel('Học tập');
    }
    if (lower.contains('y te') || lower.contains('thuoc') || lower.contains('vien')) {
      return _codeByLabel('Y tế');
    }

    return _codeByLabel('Ví chung');
  }

  final nameCtrl = TextEditingController();
  final budgetCtrl = TextEditingController();
  final topUpCtrl = TextEditingController();

  int? iconCode;
  int? _boundWalletId;

  String money(double v) => NumberFormat.decimalPattern('vi_VN').format(v);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnvelopeProvider>().loadEnvelopeDetail(widget.walletId);
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    budgetCtrl.dispose();
    topUpCtrl.dispose();
    super.dispose();
  }

  // [CAP_NHAT_VI] Nhập dữ liệu chỉnh sửa và lưu cập nhật thông tin ví.
  Future<void> saveEdit() async {
    final p = context.read<EnvelopeProvider>();
    final w = p.selectedWallet;
    if (w == null) return;

    final name = nameCtrl.text.trim();
    final budget = double.tryParse(budgetCtrl.text.trim());

    // [KIEM_TRA_DAU_VAO] Chặn dữ liệu không hợp lệ trước khi lưu.
    if (name.isEmpty || budget == null || budget <= 0 || iconCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập sai dữ liệu chỉnh sửa.')),
      );
      return;
    }

    // [LUU_DB] Cập nhật tên/icon/ngân sách ví.
    await p.updateEnvelope(
      id: w.id!,
      name: name,
      iconCode: iconCode!,
      budget: budget,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu chỉnh sửa.')));
  }

  // [NAP_TIEN_THU_CONG] Nhập số tiền và cộng trực tiếp vào ví.
  Future<void> topUp() async {
    final p = context.read<EnvelopeProvider>();
    final w = p.selectedWallet;
    if (w == null) return;

    final amount = double.tryParse(topUpCtrl.text.trim());
    // [KIEM_TRA_DAU_VAO] Số tiền nạp phải là số dương.
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền nạp không hợp lệ.')),
      );
      return;
    }

    // [LUU_DB] Nạp tiền thủ công và lưu trực tiếp xuống DB.
    await p.topUpManual(w.id!, amount);
    topUpCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nạp tiền thành công.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết / Chỉnh sửa túi tiền')),
      body: Consumer<EnvelopeProvider>(
        builder: (_, p, __) {
          if (p.isLoading && p.selectedWallet == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final w = p.selectedWallet;
          if (w == null)
            return const Center(child: Text('Không có dữ liệu túi.'));

          // Khi đổi sang ví khác, cập nhật lại dữ liệu lên form.
          final currentWalletId = w.id ?? widget.walletId;
          if (_boundWalletId != currentWalletId) {
            nameCtrl.text = w.name;
            budgetCtrl.text = w.budget.toStringAsFixed(0);
            iconCode = w.iconCode;

            // Chuyen icon code cu/la ve icon hop le de dropdown hien thi dung.
            if (!_isKnownCode(iconCode)) {
              iconCode = _guessCodeByWalletName(w.name);
            }
            _boundWalletId = currentWalletId;
          }

          final spent = w.budget - w.balance;
          final progress = w.budget <= 0
              ? 0.0
              : (spent / w.budget).clamp(0.0, 1.0);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Túi: ${w.name}'),
                      Text('Ngân sách: ${money(w.budget)} VND'),
                      Text('Đã tiêu: ${money(spent)} VND'),
                      Text('Còn lại: ${money(w.balance)} VND'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Chỉnh sửa túi'),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên túi'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ngân sách mới'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: iconCode,
                decoration: const InputDecoration(labelText: 'Icon'),
                items: kWalletIconOptions
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item.code,
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: item.color,
                            ),
                            const SizedBox(width: 8),
                            Text(item.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => iconCode = v),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: saveEdit,
                child: const Text('Lưu chỉnh sửa'),
              ),

              const SizedBox(height: 16),
              const Text('Nạp tiền thủ công'),
              const SizedBox(height: 8),
              TextField(
                controller: topUpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nhập số tiền muốn nạp',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: topUp, child: const Text('Nạp tiền')),

              const SizedBox(height: 16),
              const Text('Danh sách thu/chi của túi'),
              const SizedBox(height: 8),
              if (p.selectedWalletTransactions.isEmpty)
                const Text('Chưa có giao dịch.')
              else
                ...p.selectedWalletTransactions.map((tx) {
                  final amount = (tx['amount'] as num).toDouble();
                  final type = tx['transactionType'] as String;
                  final note = (tx['note'] as String?) ?? '';
                  final isExpense = type == 'EXPENSE';

                  return ListTile(
                    leading: Icon(
                      isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                    title: Text(note.isEmpty ? 'Không có ghi chú' : note),
                    trailing: Text(
                      '${isExpense ? '-' : '+'}${money(amount)}',
                      style: TextStyle(
                        color: isExpense ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
