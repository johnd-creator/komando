import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../data/models/finance_model.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';

class _Format {
  static String amount(double a) => a == a.roundToDouble()
      ? a.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )
      : a
            .toStringAsFixed(0)
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]}.',
            );
}

class LedgerDetailScreen extends StatelessWidget {
  const LedgerDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FinanceBloc, FinanceState>(
      listener: (context, state) {
        if (state is FinanceActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is FinanceActionFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is FinanceLedgerDetailLoaded) {
          return _DetailBody(
            ledger: state.ledger,
            userRole: state.userRole,
            id: id,
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Detail Transaksi')),
          body: Builder(
            builder: (context) {
              if (state is FinanceLoading) {
                return const LoadingState(
                  message: 'Memuat detail transaksi...',
                );
              }
              if (state is FinanceActionFailure) {
                return ErrorState(
                  message: state.message,
                  onRetry: () => context.read<FinanceBloc>().add(
                    FinanceLedgerDetailFetched(id),
                  ),
                );
              }
              if (state is FinanceActionSuccess) {
                return const LoadingState(message: 'Memuat ulang...');
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.ledger,
    required this.userRole,
    required this.id,
  });

  final FinanceLedgerModel ledger;
  final UserRoleInfo userRole;
  final int id;

  bool get _canApprove =>
      userRole.normalizedRole == 'bendahara' ||
      userRole.normalizedRole == 'bendahara_pusat' ||
      userRole.normalizedRole == 'super_admin' ||
      userRole.normalizedRole == 'superadmin';

  @override
  Widget build(BuildContext context) {
    final isIncome = ledger.type == 'income';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<FinanceBloc>().add(FinanceLedgerDetailFetched(id));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isIncome ? 'Pemasukan' : 'Pengeluaran',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                        ),
                        const Spacer(),
                        _StatusChip(status: ledger.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Jumlah',
                      value: 'Rp ${_Format.amount(ledger.amount)}',
                    ),
                    _Field(label: 'Tanggal', value: ledger.date),
                    _Field(label: 'Deskripsi', value: ledger.description),
                    _Field(label: 'Kategori', value: ledger.categoryName),
                    if (ledger.unit != null)
                      _Field(label: 'Unit', value: ledger.unit!.name),
                    if (ledger.createdBy != null)
                      _Field(label: 'Dibuat oleh', value: ledger.createdByName),
                    if (ledger.status == 'rejected' &&
                        ledger.rejectionReason != null &&
                        ledger.rejectionReason!.isNotEmpty)
                      _Field(
                        label: 'Alasan Ditolak',
                        value: ledger.rejectionReason!,
                      ),
                  ],
                ),
              ),
            ),
            if (ledger.status == 'submitted' && _canApprove) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.read<FinanceBloc>().add(
                        FinanceLedgerApproved(id),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Setujui'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.financeLedgerEdit(id)),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            if (ledger.status == 'approved' && _canApprove) ...[
              const SizedBox(height: 8),
              Text(
                'Transaksi ini sudah disetujui.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ],
            if (ledger.status == 'rejected' && _canApprove) ...[
              const SizedBox(height: 8),
              Text(
                'Transaksi ini sudah ditolak.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Transaksi'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Alasan penolakan...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final reason = ctrl.text.trim();
              if (reason.isEmpty) return;
              context.read<FinanceBloc>().add(
                FinanceLedgerRejected(id: id, reason: reason),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Transaksi ini akan dihapus dari ledger.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              context.read<FinanceBloc>().add(FinanceLedgerDeleted(id));
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
