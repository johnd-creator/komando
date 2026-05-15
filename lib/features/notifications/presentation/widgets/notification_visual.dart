import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';

class NotificationVisual {
  const NotificationVisual({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  factory NotificationVisual.from(NotificationModel notification) {
    final category = notification.category.toLowerCase();
    final type = notification.type.toLowerCase();

    if (category == 'finance' || category == 'dues' || type == 'finance') {
      return const NotificationVisual(
        icon: Icons.monetization_on_outlined,
        foreground: Color(0xFF0B7A35),
        background: Color(0xFFEAF7EC),
      );
    }
    if (category == 'aspiration' || type == 'aspiration') {
      return const NotificationVisual(
        icon: Icons.chat_bubble_outline_rounded,
        foreground: Color(0xFF5134D4),
        background: Color(0xFFF0ECFF),
      );
    }
    if (category == 'letter' || type == 'letter') {
      return const NotificationVisual(
        icon: Icons.mail_outline_rounded,
        foreground: Color(0xFFC27803),
        background: Color(0xFFFFF7E6),
      );
    }
    if (category == 'announcement') {
      return const NotificationVisual(
        icon: Icons.event_note_outlined,
        foreground: Color(0xFF0967D8),
        background: Color(0xFFEAF4FF),
      );
    }
    if (category == 'membership') {
      return const NotificationVisual(
        icon: Icons.badge_outlined,
        foreground: Color(0xFF0967D8),
        background: Color(0xFFEAF4FF),
      );
    }
    return const NotificationVisual(
      icon: Icons.settings_outlined,
      foreground: AppColors.textMuted,
      background: Color(0xFFF1F5F9),
    );
  }
}
