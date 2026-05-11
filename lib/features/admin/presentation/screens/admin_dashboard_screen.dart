import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const AdminDashboardFetched());
  }

  void _reload() {
    context.read<AdminBloc>().add(const AdminDashboardFetched());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminInitial) {
            return const SizedBox.shrink();
          }

          if (state is AdminLoading) {
            return LoadingState(message: state.message);
          }

          if (state is AdminFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          if (state is! AdminDashboardLoaded) {
            return const SizedBox.shrink();
          }

          final d = state.dashboard;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Ringkasan Admin',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatTile(
                      label: 'Anggota',
                      value: d.totalMembers.toString(),
                      icon: Icons.people,
                    ),
                    _StatTile(
                      label: 'Unit',
                      value: d.totalUnits.toString(),
                      icon: Icons.business,
                    ),
                    _StatTile(
                      label: 'Iuran Bulan Ini',
                      value: 'Rp ${_fmt(d.totalDuesThisMonth)}',
                      icon: Icons.payments,
                    ),
                    _StatTile(
                      label: 'Aspirasi',
                      value: d.totalAspirations.toString(),
                      icon: Icons.lightbulb,
                    ),
                    _StatTile(
                      label: 'Surat',
                      value: d.totalLetters.toString(),
                      icon: Icons.mail,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Menunggu Approval',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (d.pendingLedgers +
                        d.pendingOnboarding +
                        d.pendingUpdates +
                        d.pendingMutations ==
                    0)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Tidak ada yang menunggu approval'),
                      ),
                    ),
                  )
                else ...[
                  if (d.pendingLedgers > 0)
                    _PendingCard(
                      label: 'Transaksi Keuangan',
                      count: d.pendingLedgers,
                      onTap: () => context.push(AppRoutes.keuangan),
                    ),
                  if (d.pendingOnboarding > 0)
                    _PendingCard(
                      label: 'Pendaftaran Baru',
                      count: d.pendingOnboarding,
                      onTap: () {},
                    ),
                  if (d.pendingUpdates > 0)
                    _PendingCard(
                      label: 'Perubahan Data',
                      count: d.pendingUpdates,
                      onTap: () {},
                    ),
                  if (d.pendingMutations > 0)
                    _PendingCard(
                      label: 'Mutasi Anggota',
                      count: d.pendingMutations,
                      onTap: () {},
                    ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Menu Admin',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Data Anggota'),
                  subtitle: const Text('Kelola dan cari anggota'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.adminMembers),
                ),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Kelola Iuran'),
                  subtitle: const Text('Checklist & tagihan iuran bulanan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.adminDues),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('Keuangan'),
                  subtitle: const Text('Lihat transaksi keuangan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.keuangan),
                ),
                ListTile(
                  leading: const Icon(Icons.assessment),
                  title: const Text('Laporan'),
                  subtitle: const Text('Ekspor laporan anggota & keuangan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.adminReports),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade50,
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

String _fmt(double amount) {
  return amount == amount.roundToDouble()
      ? amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )
      : amount
            .toStringAsFixed(0)
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]}.',
            );
}
