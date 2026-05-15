import 'package:flutter/material.dart';

import 'soft_panel.dart';

class FeatureAccessPanel extends StatelessWidget {
  const FeatureAccessPanel({
    super.key,
    required this.onIuranTap,
    required this.onAspirasiTap,
    required this.onSuratTap,
    required this.onPengumumanTap,
    required this.onBendaharaTap,
    required this.onNewsTap,
    required this.onLainnyaTap,
  });

  final VoidCallback onIuranTap;
  final VoidCallback onAspirasiTap;
  final VoidCallback onSuratTap;
  final VoidCallback onPengumumanTap;
  final VoidCallback? onBendaharaTap;
  final VoidCallback onNewsTap;
  final VoidCallback onLainnyaTap;

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akses fitur',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 4,
            childAspectRatio: 0.9,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _FeatureTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Aspirasi',
                foreground: const Color(0xFF5144D9),
                background: const Color(0xFFF0EEFF),
                onTap: onAspirasiTap,
              ),
              _FeatureTile(
                icon: Icons.mail_outline_rounded,
                label: 'Surat',
                foreground: const Color(0xFFB66A00),
                background: const Color(0xFFFFF4DF),
                onTap: onSuratTap,
              ),
              _FeatureTile(
                icon: Icons.payments_outlined,
                label: 'Iuran',
                foreground: const Color(0xFF04784A),
                background: const Color(0xFFEAF7EF),
                onTap: onIuranTap,
              ),
              _FeatureTile(
                icon: Icons.newspaper_rounded,
                label: 'News',
                foreground: const Color(0xFFC03F86),
                background: const Color(0xFFFFEEF7),
                onTap: onNewsTap,
              ),
              _FeatureTile(
                icon: Icons.notifications_active_outlined,
                label: 'Pengumuman',
                foreground: const Color(0xFFC23A2A),
                background: const Color(0xFFFFECE9),
                onTap: onPengumumanTap,
              ),
              if (onBendaharaTap != null)
                _FeatureTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Bendahara',
                  foreground: const Color(0xFF2E7D32),
                  background: const Color(0xFFEDF7E8),
                  onTap: onBendaharaTap!,
                ),
              _FeatureTile(
                icon: Icons.more_horiz_rounded,
                label: 'Lainnya',
                foreground: const Color(0xFF4B5563),
                background: const Color(0xFFF4F5F7),
                onTap: onLainnyaTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: foreground.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: foreground, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              height: 1.05,
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
