import 'package:expense_tracker/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  ({Color bg, Color fg, IconData icon}) _styleForType(String type) {
    if (type == 'LOW_BALANCE_NEGATIVE') {
      return (
        bg: const Color(0xFFFEE2E2),
        fg: const Color(0xFFB91C1C),
        icon: Icons.warning_amber_rounded,
      );
    }

    if (type == 'LOW_BALANCE_20') {
      return (
        bg: const Color(0xFFFFEDD5),
        fg: const Color(0xFFC2410C),
        icon: Icons.notifications_active_outlined,
      );
    }

    return (
      bg: const Color(0xFFDBEAFE),
      fg: const Color(0xFF1D4ED8),
      icon: Icons.bedtime_outlined,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<NotificationProvider>();
      await provider.loadInitialData();
      await provider.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FA),
      appBar: AppBar(
        title: const Text('Thông báo hệ thống'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.notifications_rounded),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
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

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 36,
                      color: Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Khi phát sinh cảnh báo số dư hoặc nhắc buổi tối, hệ thống sẽ hiển thị ở đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refreshData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                          'Kéo xuống để làm mới danh sách thông báo.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF075985),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...provider.notifications.map((item) {
                  final createdAt = DateTime.tryParse(
                    item['createdAt'] as String? ?? '',
                  );
                  final timeText = createdAt == null
                      ? '-'
                      : DateFormat('HH:mm dd/MM/yyyy').format(createdAt);
                  final type = item['type'] as String? ?? '';
                  final style = _styleForType(type);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: style.bg),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: style.bg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(style.icon, color: style.fg),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String? ?? 'Thông báo',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item['message'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF334155),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timeText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
