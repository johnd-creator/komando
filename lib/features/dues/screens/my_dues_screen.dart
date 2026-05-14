import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/widgets/section_header.dart';
import '../bloc/dues_bloc.dart';
import '../bloc/dues_event.dart';
import '../bloc/dues_state.dart';
import '../models/dues_payment.dart';
import '../models/dues_summary.dart';

class MyDuesScreen extends StatefulWidget {
  const MyDuesScreen({super.key});

  @override
  State<MyDuesScreen> createState() => _MyDuesScreenState();
}

class _MyDuesScreenState extends State<MyDuesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DuesBloc>().add(LoadMyDues());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocBuilder<DuesBloc, DuesState>(
        builder: (context, state) {
          if (state.status == DuesStatus.loading ||
              state.status == DuesStatus.initial) {
            return const _LoadingView();
          }
          if (state.status == DuesStatus.error) {
            return _ErrorView(
              message: state.errorMessage ?? 'Terjadi kesalahan',
              onRetry: () => context.read<DuesBloc>().add(LoadMyDues()),
            );
          }
          if (!state.hasMember) {
            return const _NoMemberView();
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<DuesBloc>().add(RefreshMyDues()),
            child: CustomScrollView(
              slivers: [
                const FeaturePageHeader(
                  title: 'Iuran Saya',
                  icon: Icons.account_balance_wallet_outlined,
                  subtitle: 'Riwayat pembayaran iuran anggota',
                ),
                if (state.summary != null)
                  SliverToBoxAdapter(
                    child: _SummarySection(
                      summary: state.summary!,
                      defaultAmount: state.defaultAmount,
                    ),
                  ),
                if (state.payments.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Belum ada data iuran.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.builder(
                      itemCount: state.payments.length,
                      itemBuilder: (context, index) => _DuesPaymentCard(
                        payment: state.payments[index],
                        isLast: index == state.payments.length - 1,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Summary Section ──────────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary, required this.defaultAmount});

  final DuesSummary summary;
  final double defaultAmount;

  String _formatAmount(double amount) {
    if (amount <= 0) return '-';
    return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = summary.currentStatus == 'paid';
    final isWaived = summary.currentStatus == 'waived';
    final statusColor = isPaid
        ? Colors.green
        : isWaived
        ? Colors.blue
        : Colors.orange;
    final statusLabel = isPaid
        ? 'Lunas'
        : isWaived
        ? 'Dibebaskan'
        : 'Belum Bayar';
    final statusIcon = isPaid
        ? Icons.check_circle_rounded
        : isWaived
        ? Icons.star_rounded
        : Icons.warning_amber_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current period card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [statusColor.withValues(alpha: 0.85), statusColor],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Periode ${_formatPeriod(summary.currentPeriod)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (defaultAmount > 0)
                        Text(
                          '${_formatAmount(defaultAmount)} / bulan',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Tunggakan',
                  value: summary.unpaidCount.toString(),
                  unit: 'bulan',
                  color: summary.unpaidCount > 0 ? Colors.red : Colors.green,
                  icon: summary.unpaidCount > 0
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Iuran Bulanan',
                  value: defaultAmount > 0
                      ? 'Rp ${(defaultAmount / 1000).toStringAsFixed(0)}rb'
                      : '-',
                  unit: 'per bulan',
                  color: const Color(0xFF1565C0),
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          if (summary.unpaidPeriods.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.red.shade400,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Periode belum dibayar:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: summary.unpaidPeriods
                              .map(
                                (p) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatPeriod(p),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Riwayat Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatPeriod(String period) {
    try {
      final parts = period.split('-');
      if (parts.length == 2) {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ];
        final m = int.parse(parts[1]);
        if (m >= 1 && m <= 12) return '${months[m - 1]} ${parts[0]}';
      }
    } catch (_) {}
    return period;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment Card ─────────────────────────────────────────────────────────────

class _DuesPaymentCard extends StatelessWidget {
  const _DuesPaymentCard({required this.payment, this.isLast = false});

  final DuesPayment payment;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.isPaid;
    final isWaived = payment.isWaived;
    final color = isPaid
        ? Colors.green
        : isWaived
        ? Colors.blue
        : Colors.orange;
    final label = isPaid
        ? 'Lunas'
        : isWaived
        ? 'Dibebaskan'
        : 'Belum Bayar';
    final icon = isPaid
        ? Icons.check_circle_rounded
        : isWaived
        ? Icons.star_rounded
        : Icons.radio_button_unchecked_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.formattedPeriod,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  if (payment.paidAt != null && payment.paidAt!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Dibayar: ${payment.paidAt!.substring(0, 10)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      payment.notes!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(label: label, color: color),
                if (isPaid && payment.amount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatAmount(payment.amount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}

// ─── Utility Views ────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        FeaturePageHeader(
          title: 'Iuran Saya',
          icon: Icons.account_balance_wallet_outlined,
        ),
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const FeaturePageHeader(
          title: 'Iuran Saya',
          icon: Icons.account_balance_wallet_outlined,
        ),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoMemberView extends StatelessWidget {
  const _NoMemberView();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        FeaturePageHeader(
          title: 'Iuran Saya',
          icon: Icons.account_balance_wallet_outlined,
        ),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Profil anggota belum terhubung',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hubungi admin untuk menghubungkan akun Anda dengan data anggota.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
