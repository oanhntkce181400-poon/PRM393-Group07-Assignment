import 'dart:ui';

import 'package:expense_tracker/providers/goal_provider.dart';
import 'package:expense_tracker/screens/add_edit_goal_screen.dart';
import 'package:expense_tracker/screens/goal_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GoalListScreen extends StatelessWidget {
  const GoalListScreen({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditGoalScreen()),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: Consumer<GoalProvider>(
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

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                stretch: true,
                expandedHeight: 200,
                backgroundColor: Colors.white.withValues(alpha: 0.72),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.16),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
                title: Text(
                  'Quỹ tiết kiệm mục tiêu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    const minHeight = kToolbarHeight;
                    const maxHeight = 200.0;
                    final progress = ((constraints.biggest.height - minHeight) / (maxHeight - minHeight))
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
                                    color: const Color(0xFF34D399).withValues(alpha: 0.13),
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
                                    color: const Color(0xFF14B8A6).withValues(alpha: 0.11),
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
                                        color: Colors.white.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.65),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tạo động lực tiết kiệm',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Đặt mục tiêu và theo dõi tiến độ của bạn',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: const Color(0xFF334155),
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
              if (provider.goals.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Chưa có mục tiêu nào. Nhấn + để thêm mới.'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                  sliver: SliverList.separated(
                    itemCount: provider.goals.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final goal = provider.goals[index];
                      final goalId = goal.id ?? 0;
                      final progressPercentage = provider.getProgressPercentage(goal);
                      final startDate = DateTime.tryParse(goal.startDate);
                      final formattedStartDate = startDate == null
                          ? '-'
                          : DateFormat('dd/MM/yyyy').format(startDate);

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
                          key: ValueKey(goalId),
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
                                    title: const Text('Xóa mục tiêu?'),
                                    content: const Text(
                                      'Hành động này sẽ xóa mục tiêu tiết kiệm của bạn.',
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
                            await context.read<GoalProvider>().deleteGoal(goalId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã xóa mục tiêu.')),
                              );
                            }
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GoalDetailScreen(goal: goal),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Goal name and progress percentage
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            goal.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${progressPercentage.toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              color: Color(0xFF0F766E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Amount display
                                    Text(
                                      '${_formatCurrency(goal.currentAmount)} / ${_formatCurrency(goal.targetAmount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                  // Progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (progressPercentage / 100).clamp(0.0, 1.0),
                                      minHeight: 10,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progressPercentage >= 100
                                            ? Colors.green
                                            : const Color(0xFF0F766E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Start date
                                  Text(
                                    'Ngày bắt đầu: $formattedStartDate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
