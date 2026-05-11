import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dues_admin_bloc.dart';
import '../bloc/dues_admin_event.dart';
import '../bloc/dues_admin_state.dart';
import '../widgets/dues_filter_bar.dart';
import '../widgets/dues_status_badge.dart';
import '../widgets/dues_mass_pay_dialog.dart';
import '../models/dues_mass_update_item.dart';

class DuesAdminListScreen extends StatefulWidget {
  const DuesAdminListScreen({super.key});

  @override
  State<DuesAdminListScreen> createState() => _DuesAdminListScreenState();
}

class _DuesAdminListScreenState extends State<DuesAdminListScreen> {
  final Set<int> _selectedMemberIds = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<DuesAdminBloc>().add(const LoadAdminDues(canChecklist: true));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<DuesAdminBloc>().add(LoadMoreAdminDues());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Iuran Anggota')),
      body: BlocBuilder<DuesAdminBloc, DuesAdminState>(
        builder: (context, state) {
          return Column(
            children: [
              if (state.summary != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                      _buildSummaryItem(
                        'Bebas',
                        state.summary!.waived,
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              DuesFilterBar(
                currentFilters: state.filters,
                onFilterChanged: (filters) {
                  context.read<DuesAdminBloc>().add(UpdateFilter(filters));
                },
              ),
              Expanded(
                child: state.status == DuesAdminStatus.loading
                    ? const Center(child: CircularProgressIndicator())
                    : state.status == DuesAdminStatus.error
                    ? Center(child: Text(state.errorMessage ?? 'Error'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            state.payments.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.payments.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final payment = state.payments[index];
                          // We assume DuesPayment has member ID or we use index for now since it's mock
                          // In real API, DuesPayment returned by admin endpoints contains member info
                          final mockMemberId =
                              index; // Replace with actual payment.member.id

                          return ListTile(
                            leading: state.canChecklist && !payment.isPaid
                                ? Checkbox(
                                    value: _selectedMemberIds.contains(
                                      mockMemberId,
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedMemberIds.add(mockMemberId);
                                        } else {
                                          _selectedMemberIds.remove(
                                            mockMemberId,
                                          );
                                        }
                                      });
                                    },
                                  )
                                : null,
                            title: Text('Anggota $mockMemberId'), // mock name
                            subtitle: Text(payment.formattedPeriod),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                DuesStatusBadge(status: payment.status),
                                const SizedBox(height: 4),
                                Text('Rp ${payment.amount.toStringAsFixed(0)}'),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedMemberIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => DuesMassPayDialog(
                    count: _selectedMemberIds.length,
                    defaultAmount: 30000, // Replace with config default
                  ),
                );

                if (result != null && mounted) {
                  final items = _selectedMemberIds
                      .map(
                        (id) => DuesMassUpdateItem(
                          memberId: id,
                          period: '2026-05', // Mock current period
                          status: 'paid',
                          amount: result['amount'],
                          notes: result['notes'],
                        ),
                      )
                      .toList();

                  context.read<DuesAdminBloc>().add(MassUpdateDues(items));
                  setState(() {
                    _selectedMemberIds.clear();
                  });
                }
              },
              icon: const Icon(Icons.payment),
              label: Text('Bayar ${_selectedMemberIds.length}'),
            )
          : null,
    );
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
}
