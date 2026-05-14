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
      backgroundColor: const Color(0xFFF3F7FC),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminInitial) {
            return const SizedBox.shrink();
          }

          if (state is AdminLoading) {
            return Column(
              children: [
                const _AdminHeader(),
                Expanded(child: LoadingState(message: state.message)),
              ],
            );
          }

          if (state is AdminFailure) {
            return Column(
              children: [
                const _AdminHeader(),
                Expanded(
                  child: ErrorState(message: state.message, onRetry: _reload),
                ),
              ],
            );
          }

          if (state is! AdminDashboardLoaded) {
            return const SizedBox.shrink();
          }

          final d = state.dashboard;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const _AdminHeader(),
                const SizedBox(height: 18),
                _SummaryPanel(
                  children: [
                    _StatTile(
                      label: 'Anggota',
                      value: d.totalMembers.toString(),
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF126ED3),
                    ),
                    _StatTile(
                      label: 'Saldo Uang',
                      value: 'Rp ${_fmt(d.totalDuesThisMonth)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF159B56),
                    ),
                    _StatTile(
                      label: 'Aspirasi',
                      value: d.totalAspirations.toString(),
                      icon: Icons.forum_rounded,
                      color: const Color(0xFF5A3FD6),
                    ),
                    _StatTile(
                      label: 'Surat',
                      value: d.totalLetters.toString(),
                      icon: Icons.mail_rounded,
                      color: const Color(0xFFE18A00),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ApprovalPanel(
                  pendingLedgers: d.pendingLedgers,
                  pendingOnboarding: d.pendingOnboarding,
                  pendingUpdates: d.pendingUpdates,
                  pendingMutations: d.pendingMutations,
                  onLedgerTap: () => context.push(AppRoutes.keuangan),
                ),
                const SizedBox(height: 14),
                _MenuPanel(
                  children: [
                    _AdminMenuTile(
                      title: 'Data Anggota',
                      subtitle: 'Kelola dan cari data anggota.',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF126ED3),
                      onTap: () => context.push(AppRoutes.adminMembers),
                    ),
                    _AdminMenuTile(
                      title: 'Kelola Iuran',
                      subtitle: 'Checklist dan tagihan iuran bulanan.',
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF159B56),
                      onTap: () => context.push(AppRoutes.adminDues),
                    ),
                    _AdminMenuTile(
                      title: 'Transaksi Keuangan',
                      subtitle: 'Monitoring pemasukan, pengeluaran, approval.',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF5A3FD6),
                      onTap: () => context.push(AppRoutes.keuangan),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.paddingOf(context).top + 194,
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
          Opacity(
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
                        'Admin Panel',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Dashboard Admin',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pantau anggota, keuangan, aspirasi, surat, dan approval.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      height: 1.3,
                    ),
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Ringkasan Admin',
      icon: Icons.dashboard_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children
                .map((child) => SizedBox(width: width, child: child))
                .toList(),
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
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF071A3A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF5C6D86),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalPanel extends StatelessWidget {
  const _ApprovalPanel({
    required this.pendingLedgers,
    required this.pendingOnboarding,
    required this.pendingUpdates,
    required this.pendingMutations,
    required this.onLedgerTap,
  });

  final int pendingLedgers;
  final int pendingOnboarding;
  final int pendingUpdates;
  final int pendingMutations;
  final VoidCallback onLedgerTap;

  @override
  Widget build(BuildContext context) {
    final total =
        pendingLedgers + pendingOnboarding + pendingUpdates + pendingMutations;

    return _PanelCard(
      title: 'Menunggu Approval',
      icon: Icons.pending_actions_rounded,
      trailing: _CountPill(count: total, emphasized: total > 0),
      child: Column(
        children: [
          _ApprovalRow(
            label: 'Transaksi Keuangan',
            count: pendingLedgers,
            icon: Icons.account_balance_wallet_rounded,
            onTap: onLedgerTap,
          ),
          _ApprovalRow(
            label: 'Pendaftaran Baru',
            count: pendingOnboarding,
            icon: Icons.person_add_alt_1_rounded,
            onTap: () {},
          ),
          _ApprovalRow(
            label: 'Perubahan Data',
            count: pendingUpdates,
            icon: Icons.manage_accounts_rounded,
            onTap: () {},
          ),
          _ApprovalRow(
            label: 'Mutasi Anggota',
            count: pendingMutations,
            icon: Icons.swap_horiz_rounded,
            onTap: () {},
            showDivider: false,
          ),
          if (total == 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F9FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Tidak ada item yang menunggu approval.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5C6D86),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApprovalRow extends StatelessWidget {
  const _ApprovalRow({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
    this.showDivider = true,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4DE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFFE18A00), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF071A3A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _CountPill(count: count, emphasized: count > 0),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8A9AAF),
                ),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1, color: Color(0xFFE2ECF7)),
        ],
      ),
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Menu Admin',
      icon: Icons.apps_rounded,
      child: Column(children: children),
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  const _AdminMenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F9FD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2ECF7)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF071A3A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5C6D86),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A9AAF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF126ED3), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF071A3A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.emphasized});

  final int count;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized ? const Color(0xFFFFF4DE) : const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        count.toString(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: emphasized ? const Color(0xFFE18A00) : const Color(0xFF126ED3),
          fontWeight: FontWeight.w900,
        ),
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
