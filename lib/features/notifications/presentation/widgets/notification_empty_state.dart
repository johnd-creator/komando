import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'notification_helpers.dart';

class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({super.key, required this.selectedCategory});

  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    final label = selectedCategory == 'all'
        ? 'notifikasi'
        : categoryLabel(selectedCategory).toLowerCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF0967D8),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada $label',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF0B1B37),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi anggota akan tampil di sini.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
