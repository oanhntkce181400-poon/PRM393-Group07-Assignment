import 'package:expense_tracker/models/goal.dart';
import 'package:expense_tracker/providers/goal_provider.dart';
import 'package:expense_tracker/screens/add_edit_goal_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({
    super.key,
    required this.goal,
  });

  final Goal goal;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late Goal _currentGoal;

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.goal;
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa mục tiêu?'),
            content: const Text('Mục tiêu này sẽ bị xóa vĩnh viễn.'),
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

    await context.read<GoalProvider>().deleteGoal(_currentGoal.id!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa mục tiêu.')),
    );
    Navigator.pop(context, true);
  }

  void _showFundingDialog() {
    final fundingController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(dialogContext).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nạp tiền vào mục tiêu',
              style: Theme.of(dialogContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Amount input
            TextField(
              controller: fundingController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Số tiền nạp',
                hintText: 'Nhập số tiền',
                suffixText: 'VND',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description input
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'Nhập ghi chú',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final amountText = fundingController.text.trim();
                      if (amountText.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập số tiền'),
                          ),
                        );
                        return;
                      }

                      final amount = double.tryParse(amountText);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập số tiền hợp lệ'),
                          ),
                        );
                        return;
                      }

                      // Perform funding update
                      final provider = context.read<GoalProvider>();
                      final newAmount = (_currentGoal.currentAmount + amount)
                          .clamp(0.0, _currentGoal.targetAmount);
                      
                      final updatedGoal = Goal(
                        id: _currentGoal.id,
                        name: _currentGoal.name,
                        targetAmount: _currentGoal.targetAmount,
                        currentAmount: newAmount,
                        startDate: _currentGoal.startDate,
                        endDate: _currentGoal.endDate,
                      );

                      try {
                        await provider.updateGoal(updatedGoal);
                        setState(() {
                          _currentGoal = updatedGoal;
                        });
                        
                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Nạp tiền thành công: +${NumberFormat.decimalPattern('vi_VN').format(amount)} VND',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Nạp tiền'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage =
        (_currentGoal.currentAmount / _currentGoal.targetAmount) * 100;
    final startDate = DateTime.tryParse(_currentGoal.startDate);
    final formattedStartDate = startDate == null
        ? '-'
        : DateFormat('dd/MM/yyyy').format(startDate);
    final endDate = DateTime.tryParse(_currentGoal.endDate);
    final formattedEndDate =
        endDate == null ? '-' : DateFormat('dd/MM/yyyy').format(endDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết mục tiêu'),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Chỉnh sửa'),
                onTap: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditGoalScreen(existingGoal: _currentGoal),
                    ),
                  );

                  if (changed == true && mounted) {
                    // Reload goal data
                    final reloadedGoal =
                        await context.read<GoalProvider>().getGoalById(
                              _currentGoal.id!,
                            );
                    if (reloadedGoal != null) {
                      setState(() {
                        _currentGoal = reloadedGoal;
                      });
                    }
                  }
                },
              ),
              PopupMenuItem(
                child: const Text('Xóa'),
                onTap: _confirmDelete,
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal name and progress
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _currentGoal.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${progressPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (progressPercentage / 100).clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressPercentage >= 100
                            ? Colors.green
                            : const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Amount display
                  Text(
                    '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_currentGoal.currentAmount)} / ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_currentGoal.targetAmount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Details section
            Text(
              'Thông tin chi tiết',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),

            _DetailItem(
              label: 'Ngày bắt đầu',
              value: formattedStartDate,
            ),
            _DetailItem(
              label: 'Ngày kết thúc',
              value: formattedEndDate,
            ),
            _DetailItem(
              label: 'Số tiền cần đạt',
              value: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                  .format(_currentGoal.targetAmount),
            ),
            _DetailItem(
              label: 'Số tiền hiện có',
              value: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                  .format(_currentGoal.currentAmount),
            ),
            _DetailItem(
              label: 'Còn lại',
              value: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                  .format(
                    (_currentGoal.targetAmount - _currentGoal.currentAmount)
                        .clamp(0.0, double.infinity),
                  ),
            ),
            const SizedBox(height: 24),

            // Funding button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _showFundingDialog,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Nạp tiền vào mục tiêu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
