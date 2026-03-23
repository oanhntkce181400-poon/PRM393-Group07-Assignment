import 'package:expense_tracker/constants/wallet_icons.dart';
import 'package:expense_tracker/providers/envelope_provider.dart';
import 'package:expense_tracker/screens/envelop_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EnvelopeManagementScreen extends StatefulWidget {
  const EnvelopeManagementScreen({super.key});

  @override
  State<EnvelopeManagementScreen> createState() =>
      _EnvelopeManagementScreenState();
}

class _EnvelopeManagementScreenState extends State<EnvelopeManagementScreen> {
  WalletIconOption _findOptionByLabel(String label) {
    return kWalletIconOptions.firstWhere((item) => item.label == label);
  }

  WalletIconOption _walletVisual({
    required String walletName,
    required int iconCode,
  }) {
    // 1) Ưu tiên iconCode nếu nó nằm trong danh sách chuẩn.
    for (final item in kWalletIconOptions) {
      if (item.code == iconCode) {
        return item;
      }
    }

    // 2) Nếu iconCode cũ bị lệch, fallback theo tên ví để ra đúng ngữ cảnh.
    final lower = walletName.toLowerCase();

    if (lower.contains('ăn') || lower.contains('uong') || lower.contains('food')) {
      return _findOptionByLabel('Ăn uống');
    }
    if (lower.contains('trọ') || lower.contains('tro') || lower.contains('nhà') || lower.contains('nha')) {
      return _findOptionByLabel('Nhà ở / Trọ');
    }
    if (lower.contains('đi') || lower.contains('di lai') || lower.contains('xe') || lower.contains('xăng') || lower.contains('xang') || lower.contains('travel')) {
      return _findOptionByLabel('Đi lại');
    }
    if (lower.contains('mua') || lower.contains('shop')) {
      return _findOptionByLabel('Mua sắm');
    }
    if (lower.contains('thể thao') || lower.contains('the thao') || lower.contains('bóng') || lower.contains('bong') || lower.contains('sport')) {
      return _findOptionByLabel('Thể thao');
    }
    if (lower.contains('gym') || lower.contains('tập') || lower.contains('tap')) {
      return _findOptionByLabel('Gym');
    }
    if (lower.contains('học') || lower.contains('hoc') || lower.contains('sách') || lower.contains('sach')) {
      return _findOptionByLabel('Học tập');
    }
    if (lower.contains('y tế') || lower.contains('y te') || lower.contains('thuốc') || lower.contains('thuoc') || lower.contains('viện') || lower.contains('vien')) {
      return _findOptionByLabel('Y tế');
    }

    // 3) Mặc định về ví chung.
    return _findOptionByLabel('Ví chung');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnvelopeProvider>().loadWallets();
    });
  }

  String money(double v) => NumberFormat.decimalPattern('vi_VN').format(v);

  // [NHAP_DU_LIEU_VI] Dialog nhập tên ví, ngân sách và chọn icon.
  Future<void> showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    int pickedCode = kWalletIconOptions.first.code;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tạo túi tiền'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên túi'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ngân sách'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: pickedCode,
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
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() {
                          pickedCode = v;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Tạo'),
                ),
              ],
            );
          },
        );
      },
    );

    // [XAC_NHAN_DIALOG] Chỉ xử lý khi người dùng bấm nút Tạo.
    if (result != true || !mounted) return;

    final name = nameCtrl.text.trim();
    final budget = double.tryParse(budgetCtrl.text.trim());

    // [KIEM_TRA_DU_LIEU] Chặn dữ liệu rỗng hoặc ngân sách không hợp lệ.
    if (name.isEmpty || budget == null || budget <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập sai dữ liệu.')));
      return;
    }

    // [LUU_DB] Gọi provider để thêm ví mới vào database.
    await context.read<EnvelopeProvider>().addEnvelope(
      name,
      pickedCode,
      budget,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã tạo túi tiền.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý túi tiền')),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<EnvelopeProvider>(
        builder: (_, p, __) {
          if (p.isLoading)
            return const Center(child: CircularProgressIndicator());
          if (p.errorMessage != null)
            return Center(child: Text(p.errorMessage!));
          if (p.wallets.isEmpty)
            return const Center(child: Text('Chưa có túi tiền.'));

          return ListView.builder(
            itemCount: p.wallets.length,
            itemBuilder: (_, i) {
              final w = p.wallets[i];
              final visual = _walletVisual(
                walletName: w.name,
                iconCode: w.iconCode,
              );
              final walletIcon = visual.icon;
              final walletColor = visual.color;
              final spent = w.budget - w.balance;
              final progress = w.budget <= 0
                  ? 0.0
                  : (spent / w.budget).clamp(0.0, 1.0);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: walletColor.withValues(alpha: 0.16),
                    child: Icon(walletIcon, color: walletColor),
                  ),
                  title: Text(w.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đã tiêu: ${money(spent)} VND'),
                      Text('Còn lại: ${money(w.balance)} VND'),
                      const SizedBox(height: 6),
                      // Thanh tiến độ ngân sách theo thời gian thực
                      LinearProgressIndicator(value: progress),
                    ],
                  ),
                  onTap: () async {
                    if (w.id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ví không hợp lệ (thiếu id).'),
                        ),
                      );
                      return;
                    }

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EnvelopeDetailEditScreen(walletId: w.id!),
                      ),
                    );
                    if (!mounted) return;
                    await context.read<EnvelopeProvider>().loadWallets();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
