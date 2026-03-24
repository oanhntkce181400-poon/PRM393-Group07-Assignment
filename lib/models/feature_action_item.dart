import 'package:flutter/material.dart';

class FeatureActionItem {
  const FeatureActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actionKey,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String actionKey;
}
