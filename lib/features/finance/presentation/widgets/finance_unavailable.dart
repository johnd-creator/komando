import 'package:flutter/material.dart';

class FinanceUnavailable extends StatelessWidget {
  const FinanceUnavailable({super.key, required this.onDuesTap});

  final VoidCallback onDuesTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Keuangan organisasi belum tersedia',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Akun ini belum memiliki akses ke ledger keuangan organisasi. Riwayat iuran pribadi tetap bisa dibuka dari menu Iuran.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onDuesTap,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Lihat Iuran Saya'),
            ),
          ],
        ),
      ),
    );
  }
}
