import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/currency.dart';
import '../../data/models/finance_model.dart';

class LedgerCard extends StatelessWidget {
  const LedgerCard({
    super.key,
    required this.ledger,
    required this.colorScheme,
  });

  final FinanceLedgerModel ledger;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isIncome = ledger.type == 'income';
    final typeColor = isIncome
        ? const Color(0xFF159B56)
        : const Color(0xFFE0443E);
    final typeBg = isIncome ? const Color(0xFFE8F7EE) : const Color(0xFFFFEDEA);
    final title = ledger.description.isNotEmpty
        ? ledger.description
        : 'Tanpa deskripsi';

    return InkWell(
      onTap: () => context.push(AppRoutes.financeLedgerDetail(ledger.id)),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDDE8F5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B3A75).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: typeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF071A3A),
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      ledger.date,
                      if (ledger.categoryName.isNotEmpty) ledger.categoryName,
                      if (ledger.unit != null) ledger.unit!.name,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF5C6D86),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}Rp ${_formatAmount(ledger.amount)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusBadge(status: ledger.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, backgroundColor, textColor) = switch (status) {
      'approved' => ('Disetujui', Colors.green.shade50, Colors.green.shade700),
      'submitted' => (
        'Menunggu',
        Colors.orange.shade50,
        Colors.orange.shade700,
      ),
      'rejected' => ('Ditolak', Colors.red.shade50, Colors.red.shade700),
      _ => ('Draft', Colors.grey.shade200, Colors.grey.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

String _formatAmount(double amount) => formatRupiah(amount, showPrefix: false);
