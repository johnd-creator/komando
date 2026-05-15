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
    final currentPeriodLabel =
        '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      body: BlocBuilder<DuesAdminBloc, DuesAdminState>(
        builder: (context, state) {
          return Column(
            children: [
              _DuesAdminHeader(
                periodLabel: currentPeriodLabel,
                summaryPaid: state.summary?.paid ?? 0,
                summaryUnpaid: state.summary?.unpaid ?? 0,
                totalAmount: state.summary?.totalAmount ?? 0,
                selectedCount: _selectedMemberIds.length,
                searchController: _searchController,
                onBack: () => Navigator.of(context).maybePop(),
                onPreviousMonth: () => _changeMonth(-1),
                onNextMonth: () => _changeMonth(1),
                onPickMonth: _pickMonth,
                onSearchChanged: _onSearchChanged,
                onClearSearch: _clearSearch,
              ),
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
        itemCount: state.payments.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
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

          return _AdminDueCard(
            memberName: memberName,
            memberInfo: memberInfo,
            amountLabel: payment.isPaid
                ? 'Rp ${_formatAmount(payment.amount)}'
                : 'Belum bayar',
            status: payment.status,
            canSelect: canSelect,
            selected: memberId != null && _selectedMemberIds.contains(memberId),
            onSelectedChanged: canSelect
                ? (val) {
                    setState(() {
                      if (val == true) {
                        _selectedMemberIds.add(memberId);
                      } else {
                        _selectedMemberIds.remove(memberId);
                      }
                    });
                  }
                : null,
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
        defaultAmount: duesAdminBloc.state.defaultAmount,
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

  String _formatAmount(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

class _DuesAdminHeader extends StatelessWidget {
  const _DuesAdminHeader({
    required this.periodLabel,
    required this.summaryPaid,
    required this.summaryUnpaid,
    required this.totalAmount,
    required this.selectedCount,
    required this.searchController,
    required this.onBack,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onPickMonth,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final String periodLabel;
  final int summaryPaid;
  final int summaryUnpaid;
  final double totalAmount;
  final int selectedCount;
  final TextEditingController searchController;
  final VoidCallback onBack;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onPickMonth;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B67C8), Color(0xFF228CE5)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.26,
                child: Transform.scale(
                  scale: 1.18,
                  child: Image.asset(
                    'assets/bg-asset.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kelola Iuran',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Iuran Anggota',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pantau pembayaran dan catat iuran anggota.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _HeaderStat(
                              label: 'Lunas',
                              value: summaryPaid.toString(),
                              color: const Color(0xFF19A85B),
                              textColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HeaderStat(
                              label: 'Belum',
                              value: summaryUnpaid.toString(),
                              color: const Color(0xFFFFD7D3),
                              textColor: const Color(0xFFB3261E),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HeaderStat(
                              label: 'Terkumpul',
                              value: 'Rp ${_formatMoney(totalAmount)}',
                              color: Colors.white,
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
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 270,
          child: _DuesControlCard(
            periodLabel: periodLabel,
            selectedCount: selectedCount,
            searchController: searchController,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
            onPickMonth: onPickMonth,
            onSearchChanged: onSearchChanged,
            onClearSearch: onClearSearch,
          ),
        ),
        const SizedBox(height: 436),
      ],
    );
  }

  static String _formatMoney(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}

class _DuesControlCard extends StatelessWidget {
  const _DuesControlCard({
    required this.periodLabel,
    required this.selectedCount,
    required this.searchController,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onPickMonth,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final String periodLabel;
  final int selectedCount;
  final TextEditingController searchController;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onPickMonth;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left),
                color: const Color(0xFF51627A),
              ),
              Expanded(
                child: InkWell(
                  onTap: onPickMonth,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: Color(0xFF126ED3),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            periodLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: const Color(0xFF071A3A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right),
                color: const Color(0xFF51627A),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari nama atau KTA',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : selectedCount > 0
                  ? Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          '$selectedCount dipilih',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF126ED3),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF6F9FD),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFDDE8F5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFDDE8F5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.color,
    this.textColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDueCard extends StatelessWidget {
  const _AdminDueCard({
    required this.memberName,
    required this.memberInfo,
    required this.amountLabel,
    required this.status,
    required this.canSelect,
    required this.selected,
    required this.onSelectedChanged,
  });

  final String memberName;
  final String memberInfo;
  final String amountLabel;
  final String status;
  final bool canSelect;
  final bool selected;
  final ValueChanged<bool?>? onSelectedChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          if (canSelect) ...[
            Checkbox(
              value: selected,
              onChanged: onSelectedChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_rounded, color: Color(0xFF126ED3)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF071A3A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memberInfo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5C6D86),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DuesStatusBadge(status: status),
              const SizedBox(height: 8),
              Text(
                amountLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF3F4C60),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
