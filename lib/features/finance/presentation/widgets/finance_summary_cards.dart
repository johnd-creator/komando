import 'package:flutter/material.dart';

import '../../../../core/utils/currency.dart';
import '../../data/models/finance_model.dart';

class FinanceSummaryCards extends StatelessWidget {
  const FinanceSummaryCards({
    super.key,
    required this.dashboard,
    required this.scopeLabel,
  });

  final FinanceDashboardModel dashboard;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    final s = dashboard.summary;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE8F5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3A75).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ringkasan Keuangan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF071A3A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    scopeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF126ED3),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Informasi mengikuti filter unit yang dipilih.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5C6D86)),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryTile(
                    width: cardWidth,
                    label: 'Saldo',
                    value: 'Rp ${_formatAmount(s.balance)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: colorScheme.primary,
                  ),
                  _SummaryTile(
                    width: cardWidth,
                    label: 'Pemasukan Bulan Ini',
                    value: 'Rp ${_formatAmount(s.incomeThisMonth)}',
                    icon: Icons.trending_up_rounded,
                    color: Colors.green,
                  ),
                  _SummaryTile(
                    width: cardWidth,
                    label: 'Pengeluaran Bulan Ini',
                    value: 'Rp ${_formatAmount(s.expenseThisMonth)}',
                    icon: Icons.trending_down_rounded,
                    color: Colors.red,
                  ),
                  _SummaryTile(
                    width: cardWidth,
                    label: 'Menunggu Approval',
                    value: s.pendingCount.toString(),
                    icon: Icons.hourglass_bottom_rounded,
                    color: Colors.orange,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F9FD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2ECF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAmount(double amount) => formatRupiah(amount, showPrefix: false);
