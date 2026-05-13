import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../bloc/dues_admin_bloc.dart';
import '../bloc/dues_admin_event.dart';
import '../bloc/dues_admin_state.dart';
import '../models/dues_mass_update_item.dart';
import '../widgets/dues_mass_pay_dialog.dart';
import '../widgets/dues_status_badge.dart';

class DuesAdminListScreen extends StatefulWidget {
  const DuesAdminListScreen({super.key});

  @override
  State<DuesAdminListScreen> createState() => _DuesAdminListScreenState();
}

class _DuesAdminListScreenState extends State<DuesAdminListScreen> {
  final Set<int> _selectedMemberIds = {};
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late DateTime _selectedMonth;
  bool _canChecklist = false;

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();

    final authState = context.read<AuthBloc>().state;
    String? unitId;

    if (authState is AuthAuthenticated) {
      final role = authState.user.normalizedRoleName;
      _canChecklist = const {
        'bendahara',
        'super_admin',
        'superadmin',
      }.contains(role);

      if (role == 'bendahara' || role == 'admin_unit' || role == 'pengurus') {
        unitId = authState.user.currentUnitId?.toString();
      }
    }

    final initialFilters = <String, String>{
      'period': _formatPeriod(_selectedMonth),
    };
    if (unitId != null) initialFilters['unit_id'] = unitId;

    context.read<DuesAdminBloc>().add(
      LoadAdminDues(
        canChecklist: _canChecklist,
        initialFilters: initialFilters,
      ),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatPeriod(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll >= maxScroll - 200) {
      context.read<DuesAdminBloc>().add(LoadMoreAdminDues());
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
      _selectedMemberIds.clear();
    });
    context.read<DuesAdminBloc>().add(
      UpdateFilter({'period': _formatPeriod(_selectedMonth)}),
    );
  }

  void _onSearchChanged(String value) {
    final bloc = context.read<DuesAdminBloc>();
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(_selectedMemberIds.clear);
      bloc.add(UpdateFilter({'q': value.trim()}));
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(_selectedMemberIds.clear);
    context.read<DuesAdminBloc>().add(const UpdateFilter({'q': ''}));
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _selectedMemberIds.clear();
      });
      context.read<DuesAdminBloc>().add(
        UpdateFilter({'period': _formatPeriod(_selectedMonth)}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPeriodLabel =
        '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Iuran Anggota')),
      body: BlocBuilder<DuesAdminBloc, DuesAdminState>(
        builder: (context, state) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                    ),
                    InkWell(
                      onTap: _pickMonth,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            currentPeriodLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
              if (state.summary != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryItem(
                        'Lunas',
                        state.summary!.paid,
                        Colors.green,
                      ),
                      _buildSummaryItem(
                        'Belum',
                        state.summary!.unpaid,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau KTA',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildContent(state)),
            ],
          );
        },
      ),
      floatingActionButton: _selectedMemberIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _onMassPay,
              icon: const Icon(Icons.payment),
              label: Text('Bayar ${_selectedMemberIds.length}'),
            )
          : null,
    );
  }

  Widget _buildContent(DuesAdminState state) {
    if (state.status == DuesAdminStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == DuesAdminStatus.error) {
      return Center(child: Text(state.errorMessage ?? 'Terjadi kesalahan'));
    }

    if (state.payments.isEmpty) {
      return const Center(child: Text('Tidak ada data iuran untuk bulan ini'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DuesAdminBloc>().add(
          UpdateFilter({'period': _formatPeriod(_selectedMonth)}),
        );
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: state.payments.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= state.payments.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final payment = state.payments[index];
          final memberId = payment.memberId;
          final memberName =
              payment.memberName ?? 'Anggota #${memberId ?? '-'}';
          final memberInfo = [
            if (payment.ktaNumber != null) 'KTA ${payment.ktaNumber}',
            payment.formattedPeriod,
          ].join(' • ');
          final canSelect =
              _canChecklist &&
              memberId != null &&
              !payment.isPaid &&
              !payment.isWaived;

          return ListTile(
            leading: canSelect
                ? Checkbox(
                    value: _selectedMemberIds.contains(memberId),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedMemberIds.add(memberId);
                        } else {
                          _selectedMemberIds.remove(memberId);
                        }
                      });
                    },
                  )
                : null,
            title: Text(
              memberName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(memberInfo),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                DuesStatusBadge(status: payment.status),
                const SizedBox(height: 4),
                Text(
                  payment.isPaid
                      ? 'Rp ${_formatAmount(payment.amount)}'
                      : 'Belum bayar',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onMassPay() async {
    final duesAdminBloc = context.read<DuesAdminBloc>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DuesMassPayDialog(
        count: _selectedMemberIds.length,
        defaultAmount: 30000,
      ),
    );

    if (result != null && mounted) {
      final period = _formatPeriod(_selectedMonth);
      final items = _selectedMemberIds
          .map(
            (id) => DuesMassUpdateItem(
              memberId: id,
              period: period,
              status: 'paid',
              amount: result['amount'],
              notes: result['notes'],
            ),
          )
          .toList();

      duesAdminBloc.add(MassUpdateDues(items));
      setState(_selectedMemberIds.clear);
    }
  }

  Widget _buildSummaryItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatAmount(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
