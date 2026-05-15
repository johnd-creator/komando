import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../data/models/dashboard_model.dart';
import 'soft_panel.dart';

class HomeAnnouncementCard extends StatelessWidget {
  const HomeAnnouncementCard({
    super.key,
    required this.isLoading,
    required this.announcements,
    required this.onRetry,
    this.errorMessage,
  });

  final bool isLoading;
  final List<DashboardAnnouncementModel> announcements;
  final VoidCallback onRetry;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alert terbaru',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.push(AppRoutes.announcements),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Memuat alert'),
            )
          else if (errorMessage != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.error_outline_rounded),
              title: Text(errorMessage!),
              trailing: IconButton(
                tooltip: 'Coba lagi',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
            )
          else if (announcements.isEmpty)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.campaign_outlined),
              title: Text('Belum ada alert terbaru'),
              subtitle: Text('Tarik ke bawah untuk memuat ulang.'),
            )
          else
            for (final entry in announcements.take(3).indexed) ...[
              _AnnouncementTile(
                announcement: entry.$2,
                icon: _announcementIconFor(entry.$1),
                showDivider: entry.$1 < announcements.take(3).length - 1,
              ),
            ],
        ],
      ),
    );
  }

  static IconData _announcementIconFor(int index) {
    return switch (index) {
      0 => Icons.calendar_month_outlined,
      1 => Icons.account_balance_wallet_outlined,
      _ => Icons.description_outlined,
    };
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({
    required this.announcement,
    required this.icon,
    required this.showDivider,
  });

  final DashboardAnnouncementModel announcement;
  final IconData icon;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => context.push(AppRoutes.announcements),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF0968D7),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFF1168CF), size: 27),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      if (announcement.dateLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          announcement.dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF667085)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8A98AA),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 74, color: Color(0xFFE5EAF1)),
      ],
    );
  }
}
