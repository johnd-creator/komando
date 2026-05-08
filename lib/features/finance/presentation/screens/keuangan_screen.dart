import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../data/models/finance_model.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';

class KeuanganScreen extends StatefulWidget {
  const KeuanganScreen({super.key});

  @override
  State<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends State<KeuanganScreen> {
  int? _selectedUnitId;
  String? _selectedType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(const FinanceKeuanganRequested());
  }

  void _reload() {
    context.read<FinanceBloc>().add(const FinanceKeuanganRequested());
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};
    if (_selectedType != null) filters['type'] = _selectedType;
    if (_selectedStatus != null) filters['status'] = _selectedStatus;
    if (_selectedUnitId != null) filters['unit_id'] = _selectedUnitId;
    context.read<FinanceBloc>().add(FinanceKeuanganFiltersChanged(filters));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keuangan')),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoading || state is FinanceInitial) {
            return const LoadingState(message: 'Memuat data keuangan...');
          }

          if (state is FinanceFailure) {
            if (_isUnavailableMessage(state.message)) {
              return _FinanceUnavailable(
                onDuesTap: () {
                  context.go(AppRoutes.iuran);
                },
              );
            }

            return ErrorState(message: state.message, onRetry: _reload);
          }

          if (state is! FinanceKeuanganLoaded) {
            return const SizedBox.shrink();
          }

          final data = state;
          final colorScheme = Theme.of(context).colorScheme;

          if (data.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                children: [
                  _DashboardCards(dashboard: data.dashboard),
                  _FilterBar(
                    units: data.units.units,
                    selectedUnitId: _selectedUnitId,
                    selectedType: _selectedType,
                    selectedStatus: _selectedStatus,
                    onUnitChanged: (v) {
                      setState(() => _selectedUnitId = v);
                      _applyFilters();
                    },
                    onTypeChanged: (v) {
                      setState(() => _selectedType = v);
                      _applyFilters();
                    },
                    onStatusChanged: (v) {
                      setState(() => _selectedStatus = v);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 120),
                  const EmptyState(
                    title: 'Belum ada transaksi',
                    message: 'Transaksi keuangan akan tampil di sini.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 2 + data.items.length + (data.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _DashboardCards(dashboard: data.dashboard);
                }

                if (index == 1) {
                  return _FilterBar(
                    units: data.units.units,
                    selectedUnitId: _selectedUnitId,
                    selectedType: _selectedType,
                    selectedStatus: _selectedStatus,
                    onUnitChanged: (v) {
                      setState(() => _selectedUnitId = v);
                      _applyFilters();
                    },
                    onTypeChanged: (v) {
                      setState(() => _selectedType = v);
                      _applyFilters();
                    },
                    onStatusChanged: (v) {
                      setState(() => _selectedStatus = v);
                      _applyFilters();
                    },
                  );
                }

                final itemIndex = index - 2;
                if (data.hasMore && itemIndex >= data.items.length) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: () {
                        // Not directly supported in current bloc — reload
                        _reload();
                      },
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Muat lagi'),
                    ),
                  );
                }

                return _LedgerCard(
                  ledger: data.items[itemIndex],
                  colorScheme: colorScheme,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is! FinanceKeuanganLoaded ||
              !state.dashboard.userRole.canCreateLedger) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.financeLedgerCreate),
            icon: const Icon(Icons.add),
            label: const Text('Transaksi Baru'),
          );
        },
      ),
    );
  }
}

bool _isUnavailableMessage(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('tidak memiliki akses') ||
      normalized.contains('data tidak ditemukan');
}

class _FinanceUnavailable extends StatelessWidget {
  const _FinanceUnavailable({required this.onDuesTap});

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

class _DashboardCards extends StatelessWidget {
  const _DashboardCards({required this.dashboard});

  final FinanceDashboardModel dashboard;

  @override
  Widget build(BuildContext context) {
    final s = dashboard.summary;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Keuangan',
          style: Theme.of(context).textTheme.titleMedium,
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
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
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.units,
    required this.selectedUnitId,
    required this.selectedType,
    required this.selectedStatus,
    required this.onUnitChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
  });

  final List<FinanceUnitModel> units;
  final int? selectedUnitId;
  final String? selectedType;
  final String? selectedStatus;
  final ValueChanged<int?> onUnitChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transaksi', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (units.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButtonFormField<int>(
              initialValue: selectedUnitId,
              decoration: const InputDecoration(
                labelText: 'Unit',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Unit')),
                ...units.map(
                  (u) => DropdownMenuItem(
                    value: u.id,
                    child: Text(u.isPusat ? '${u.name} (Pusat)' : u.name),
                  ),
                ),
              ],
              onChanged: onUnitChanged,
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Semua'),
              selected: selectedType == null,
              onSelected: (_) => onTypeChanged(null),
            ),
            ChoiceChip(
              label: const Text('Pemasukan'),
              selected: selectedType == 'income',
              onSelected: (_) => onTypeChanged('income'),
            ),
            ChoiceChip(
              label: const Text('Pengeluaran'),
              selected: selectedType == 'expense',
              onSelected: (_) => onTypeChanged('expense'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Semua Status'),
              selected: selectedStatus == null,
              onSelected: (_) => onStatusChanged(null),
            ),
            ChoiceChip(
              label: const Text('Disetujui'),
              selected: selectedStatus == 'approved',
              onSelected: (_) => onStatusChanged('approved'),
            ),
            ChoiceChip(
              label: const Text('Menunggu'),
              selected: selectedStatus == 'submitted',
              onSelected: (_) => onStatusChanged('submitted'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.ledger, required this.colorScheme});

  final FinanceLedgerModel ledger;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isIncome = ledger.type == 'income';

    return Card(
      child: ListTile(
        onTap: () => context.push(AppRoutes.financeLedgerDetail(ledger.id)),
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          ledger.description.isNotEmpty
              ? ledger.description
              : 'Tanpa deskripsi',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [ledger.date, if (ledger.unit != null) ledger.unit!.name].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}Rp ${_formatAmount(ledger.amount)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            _StatusBadge(status: ledger.status),
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

String _formatAmount(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
  return amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}
