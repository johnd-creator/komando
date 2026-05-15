import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../models/dues_payment.dart';

class DuesPaymentCard extends StatelessWidget {
  const DuesPaymentCard({
    required this.payment,
    this.isLast = false,
    super.key,
  });

  final DuesPayment payment;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.isPaid;
    final isWaived = payment.isWaived;
    final color = isPaid
        ? AppColors.success
        : isWaived
        ? AppColors.info
        : AppColors.warning;
    final label = isPaid
        ? 'Lunas'
        : isWaived
        ? 'Dibebaskan'
        : 'Belum Bayar';
    final icon = isPaid
        ? Icons.check_circle_rounded
        : isWaived
        ? Icons.star_rounded
        : Icons.radio_button_unchecked_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPaid
            ? Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
                width: 1,
              )
            : isWaived
            ? Border.all(color: AppColors.info.withValues(alpha: 0.2), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: isPaid
                ? AppColors.success.withValues(alpha: 0.08)
                : isWaived
                ? AppColors.info.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Status indicator with animated border
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.formattedPeriod,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (payment.paidAt != null && payment.paidAt!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Dibayar: ${payment.paidAt!.substring(0, 10)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        payment.notes!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isPaid && payment.amount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    formatRupiah(payment.amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
