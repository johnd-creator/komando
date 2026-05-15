import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_period.dart';
import '../models/dues_summary.dart';
import 'dues_stat_card.dart';

class DuesSummarySection extends StatelessWidget {
  const DuesSummarySection({
    required this.summary,
    required this.defaultAmount,
    super.key,
  });

  final DuesSummary summary;
  final double defaultAmount;

  @override
  Widget build(BuildContext context) {
    final isPaid = summary.currentStatus == 'paid';
    final isWaived = summary.currentStatus == 'waived';
    final statusColor = isPaid
        ? AppColors.success
        : isWaived
        ? AppColors.info
        : AppColors.warning;
    final statusLabel = isPaid
        ? 'Lunas'
        : isWaived
        ? 'Dibebaskan'
        : 'Belum Bayar';
    final statusIcon = isPaid
        ? Icons.check_circle_rounded
        : isWaived
        ? Icons.star_rounded
        : Icons.warning_amber_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current period card - Hero status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withValues(alpha: 0.95),
                  statusColor.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Content
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(statusIcon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Periode ${formatPeriod(summary.currentPeriod)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (defaultAmount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${defaultAmount <= 0 ? '-' : formatRupiah(defaultAmount)} / bulan',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row with improved design
          Row(
            children: [
              Expanded(
                child: DuesStatCard(
                  label: 'Tunggakan',
                  value: summary.unpaidCount.toString(),
                  unit: 'bulan',
                  color: summary.unpaidCount > 0
                      ? AppColors.error
                      : AppColors.success,
                  icon: summary.unpaidCount > 0
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  highlight: summary.unpaidCount > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DuesStatCard(
                  label: 'Iuran Bulanan',
                  value: defaultAmount > 0
                      ? 'Rp ${(defaultAmount / 1000).toStringAsFixed(0)}rb'
                      : '-',
                  unit: 'per bulan',
                  color: AppColors.primary,
                  icon: Icons.payments_outlined,
                  highlight: false,
                ),
              ),
            ],
          ),
          // Unpaid periods warning with enhanced design
          if (summary.unpaidPeriods.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.error,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Periode Belum Dibayar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summary.unpaidPeriods
                        .map(
                          (p) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              formatPeriod(p),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB91C1C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Section header with decorative element
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Riwayat Pembayaran',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
