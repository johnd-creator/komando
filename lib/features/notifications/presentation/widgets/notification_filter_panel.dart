import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'notification_helpers.dart';

class NotificationFilter {
  const NotificationFilter(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

class NotificationFilterPanel extends StatelessWidget {
  const NotificationFilterPanel({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  static const _filters = [
    NotificationFilter('all', 'Semua', Icons.apps_rounded),
    NotificationFilter('system', 'Sistem', Icons.settings_outlined),
    NotificationFilter('finance', 'Keuangan', Icons.paid_outlined),
    NotificationFilter('aspiration', 'Aspirasi', Icons.chat_bubble_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A4667).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in _filters) ...[
              _FilterChipButton(
                filter: filter,
                selected: selectedCategory == filter.value,
                onTap: () => onSelected(filter.value),
              ),
              if (filter != _filters.last) const SizedBox(width: 9),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final NotificationFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0967D8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? primary : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filter.value != 'all') ...[
                Icon(
                  filter.icon,
                  size: 20,
                  color: selected ? Colors.white : categoryColor(filter.value),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                filter.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? Colors.white : const Color(0xFF17243D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
