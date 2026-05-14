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

  String _summaryScopeLabel(List<FinanceUnitModel> units, int? selectedUnitId) {
    if (selectedUnitId == null) return 'Semua Unit';
    final matches = units.where((unit) => unit.id == selectedUnitId);
    if (matches.isEmpty) return 'Unit terpilih';
    final unit = matches.first;
    return unit.isPusat ? '${unit.name} (Pusat)' : unit.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoading || state is FinanceInitial) {
            return const Column(
              children: [
                _FinanceHeader(),
                Expanded(
                  child: LoadingState(message: 'Memuat data keuangan...'),
                ),
              ],
            );
          }

          if (state is FinanceFailure) {
            if (_isUnavailableMessage(state.message)) {
              return Column(
                children: [
                  const _FinanceHeader(),
                  Expanded(
                    child: _FinanceUnavailable(
                      onDuesTap: () {
                        context.go(AppRoutes.iuran);
                      },
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                const _FinanceHeader(),
                Expanded(
                  child: ErrorState(message: state.message, onRetry: _reload),
                ),
              ],
            );
          }

          if (state is! FinanceKeuanganLoaded) {
            return const SizedBox.shrink();
          }

          final data = state;
          final colorScheme = Theme.of(context).colorScheme;
          final stateUnitId = data.filters['unit_id'] as int?;
          if (_selectedUnitId == null && stateUnitId != null) {
            _selectedUnitId = stateUnitId;
          }
          final effectiveSelectedUnitId = _selectedUnitId ?? stateUnitId;
          final summaryScopeLabel = _summaryScopeLabel(
            data.units.units,
            effectiveSelectedUnitId,
          );

          final filterBar = _FilterBar(
            units: data.units.units,
            selectedUnitId: effectiveSelectedUnitId,
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

          return Column(
            children: [
              const _FinanceHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: data.items.isEmpty
                        ? 3
                        : 2 + data.items.length + (data.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _DashboardCards(
                          dashboard: data.dashboard,
                          scopeLabel: summaryScopeLabel,
                        );
                      }

                      if (index == 1) return filterBar;

                      if (data.items.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: EmptyState(
                            title: 'Belum ada transaksi',
                            message: 'Transaksi keuangan akan tampil di sini.',
                          ),
                        );
                      }

                      final itemIndex = index - 2;
                      if (data.hasMore && itemIndex >= data.items.length) {
                        return Center(
                          child: TextButton.icon(
                            onPressed: _reload,
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
                ),
              ),
            ],
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
            backgroundColor: const Color(0xFF126ED3),
            foregroundColor: Colors.white,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          );
        },
      ),
    );
  }
}

bool _isUnavailableMessage(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('data tidak ditemukan');
}

class _FinanceHeader extends StatelessWidget {
  const _FinanceHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.paddingOf(context).top + 190,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B67C8), Color(0xFF228CE5)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.24,
              child: Transform.scale(
                scale: 1.18,
                child: Image.asset(
                  'assets/bg-asset.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Keuangan',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaksi',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola pemasukan, pengeluaran, dan approval.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  const _DashboardCards({required this.dashboard, required this.scopeLabel});

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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 20,
                color: Color(0xFF126ED3),
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Transaksi',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF071A3A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (units.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: selectedUnitId,
              decoration: InputDecoration(
                labelText: 'Unit',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF6F9FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDDE8F5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDDE8F5)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FinanceFilterChip(
                label: 'Semua',
                selected: selectedType == null,
                onTap: () => onTypeChanged(null),
              ),
              _FinanceFilterChip(
                label: 'Pemasukan',
                selected: selectedType == 'income',
                onTap: () => onTypeChanged('income'),
              ),
              _FinanceFilterChip(
                label: 'Pengeluaran',
                selected: selectedType == 'expense',
                onTap: () => onTypeChanged('expense'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FinanceFilterChip(
                label: 'Semua Status',
                selected: selectedStatus == null,
                onTap: () => onStatusChanged(null),
              ),
              _FinanceFilterChip(
                label: 'Disetujui',
                selected: selectedStatus == 'approved',
                onTap: () => onStatusChanged('approved'),
              ),
              _FinanceFilterChip(
                label: 'Menunggu',
                selected: selectedStatus == 'submitted',
                onTap: () => onStatusChanged('submitted'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceFilterChip extends StatelessWidget {
  const _FinanceFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: const Color(0xFF126ED3),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF126ED3) : const Color(0xFFDDE8F5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? Colors.white : const Color(0xFF51627A),
        fontWeight: FontWeight.w800,
      ),
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
