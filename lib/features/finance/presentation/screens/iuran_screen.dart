import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/currency.dart';
import '../../../../core/utils/date_period.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../data/models/dues_model.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';

class IuranScreen extends StatefulWidget {
  const IuranScreen({super.key});

  @override
  State<IuranScreen> createState() => _IuranScreenState();
}

class _IuranScreenState extends State<IuranScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(const FinanceDuesFetched());
  }

  void _reload() {
    context.read<FinanceBloc>().add(const FinanceDuesFetched());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Iuran')),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoading || state is FinanceInitial) {
            return const LoadingState(message: 'Memuat data iuran...');
          }

          if (state is FinanceFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          if (state is! FinanceDuesLoaded) {
            return const SizedBox.shrink();
          }

          final dues = state.response;
          final summary = dues.summary;

          if (!dues.hasMember) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    title: 'Profil anggota belum terhubung',
                    message:
                        'Akun ini belum memiliki profil anggota sehingga iuran belum dapat ditampilkan.',
                  ),
                ],
              ),
            );
          }

          if (dues.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    title: 'Belum ada riwayat iuran',
                    message: 'Data iuran Anda akan tampil di sini.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 1 + dues.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _SummaryCard(
                    summary: summary,
                    colorScheme: colorScheme,
                    currentAmount: dues.items.isNotEmpty
                        ? dues.items.first.amount
                        : 0,
                  );
                }

                return _DueCard(
                  due: dues.items[index - 1],
                  colorScheme: colorScheme,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.colorScheme,
    required this.currentAmount,
  });

  final DuesSummary summary;
  final ColorScheme colorScheme;
  final double currentAmount;

  @override
  Widget build(BuildContext context) {
    final paidPercent = summary.totalMonths > 0
        ? summary.paidCount / summary.totalMonths
        : 0.0;

    final currentPaid =
        summary.currentStatus == 'paid' || summary.currentStatus == 'lunas';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.currentPeriod.isEmpty
                            ? 'Status Iuran'
                            : 'Status Iuran ${formatPeriod(summary.currentPeriod)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      _StatusPill(isPaid: currentPaid),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Tunggakan',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${summary.unpaidCount} bulan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: summary.unpaidCount > 0
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Iuran bulanan: ${formatRupiah(currentAmount)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Pembayaran dilakukan ke bendahara unit. Status akan diperbarui setelah bendahara mencatat pembayaran.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 28),
            Row(
              children: [
                _StatItem(
                  label: 'Lunas',
                  value: '${summary.paidCount}/${summary.totalMonths}',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                const SizedBox(width: 24),
                _StatItem(
                  label: 'Belum',
                  value: '${summary.unpaidCount}',
                  icon: Icons.watch_later_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(width: 24),
                _StatItem(
                  label: 'Total',
                  value: formatRupiah(summary.totalAmount),
                  icon: Icons.payments_outlined,
                  color: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: paidPercent,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(paidPercent * 100).toStringAsFixed(0)}% lunas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isPaid});

  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPaid ? 'Sudah Bayar' : 'Belum Bayar',
        style: TextStyle(
          color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.due, required this.colorScheme});

  final DueModel due;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isPaid = due.status == 'paid' || due.status == 'lunas';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid
              ? Colors.green.shade50
              : Colors.orange.shade50,
          child: Icon(
            isPaid ? Icons.check : Icons.pending,
            color: isPaid ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(formatPeriod(due.period)),
        subtitle: Text(
          due.paidAt != null && due.paidAt!.isNotEmpty
              ? 'Dibayar: ${due.paidAt}'
              : 'Belum dibayar',
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatRupiah(due.amount),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPaid ? 'Sudah Bayar' : 'Belum Bayar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPaid
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
