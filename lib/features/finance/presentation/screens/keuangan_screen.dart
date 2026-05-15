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
import '../widgets/finance_filters.dart';
import '../widgets/finance_header.dart';
import '../widgets/finance_summary_cards.dart';
import '../widgets/finance_unavailable.dart';
import '../widgets/ledger_card.dart';

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
                FinanceHeader(),
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
                  const FinanceHeader(),
                  Expanded(
                    child: FinanceUnavailable(
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
                const FinanceHeader(),
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

          final filterBar = FinanceFilterBar(
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
              const FinanceHeader(),
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
                        return FinanceSummaryCards(
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

                      return LedgerCard(
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
