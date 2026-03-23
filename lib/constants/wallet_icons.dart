import 'package:flutter/material.dart';

class WalletIconOption {
  final int code;
  final String label;
  final IconData icon;
  final Color color;

  const WalletIconOption({
    required this.code,
    required this.label,
    required this.icon,
    required this.color,
  });
}

// Danh sách icon ví dùng chung toàn app.
const List<WalletIconOption> kWalletIconOptions = [
  WalletIconOption(
    code: 0xe850,
    label: 'Ví chung',
    icon: Icons.account_balance_wallet,
    color: Color(0xFF2563EB),
  ),
  WalletIconOption(
    code: 0xe56c,
    label: 'Ăn uống',
    icon: Icons.fastfood,
    color: Color(0xFFF97316),
  ),
  WalletIconOption(
    code: 0xe52f,
    label: 'Đi lại',
    icon: Icons.directions_bike,
    color: Color(0xFF0EA5A4),
  ),
  WalletIconOption(
    code: 0xe88a,
    label: 'Nhà ở / Trọ',
    icon: Icons.home,
    color: Color(0xFF7C3AED),
  ),
  WalletIconOption(
    code: 0xe59c,
    label: 'Mua sắm',
    icon: Icons.shopping_bag,
    color: Color(0xFFDB2777),
  ),
  WalletIconOption(
    code: 0xe4dc,
    label: 'Thể thao',
    icon: Icons.sports_soccer,
    color: Color(0xFF16A34A),
  ),
  WalletIconOption(
    code: 0xeb43,
    label: 'Gym',
    icon: Icons.fitness_center,
    color: Color(0xFFDC2626),
  ),
  WalletIconOption(
    code: 0xe566,
    label: 'Chạy bộ',
    icon: Icons.directions_run,
    color: Color(0xFF0891B2),
  ),
  WalletIconOption(
    code: 0xe80c,
    label: 'Sức khỏe',
    icon: Icons.local_hospital,
    color: Color(0xFFE11D48),
  ),
  WalletIconOption(
    code: 0xe80f,
    label: 'Học tập',
    icon: Icons.school,
    color: Color(0xFF0284C7),
  ),
];
