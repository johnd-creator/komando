import 'package:flutter/material.dart';
import '../models/dues_summary.dart';
import 'dues_status_badge.dart';

class DuesSummaryCard extends StatelessWidget {
  final DuesSummary summary;
  final double defaultAmount;

  const DuesSummaryCard({
    super.key,
    required this.summary,
    required this.defaultAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Bulan Ini',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              DuesStatusBadge(status: summary.currentStatus),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.unpaidCount > 0
                ? '${summary.unpaidCount} bulan belum dibayar'
                : 'Tidak ada tunggakan bulan ini',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp ${defaultAmount.toStringAsFixed(0)} / bulan',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          if (summary.unpaidPeriods.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Bulan yang belum lunas:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: summary.unpaidPeriods
                  .map(
                    (p) => Chip(
                      label: Text(p, style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.red.withOpacity(0.1),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
