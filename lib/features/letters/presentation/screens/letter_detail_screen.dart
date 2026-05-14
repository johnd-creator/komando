import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../bloc/letter_bloc.dart';
import '../bloc/letter_event.dart';
import '../bloc/letter_state.dart';

class LetterDetailScreen extends StatefulWidget {
  const LetterDetailScreen({required this.id, super.key});

  final int id;

  @override
  State<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends State<LetterDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LetterBloc>().add(LetterDetailFetched(widget.id));
  }

  void _reload() {
    context.read<LetterBloc>().add(LetterDetailFetched(widget.id));
  }

  static const _statusColors = {
    'draft': Colors.grey,
    'submitted': Colors.orange,
    'approved': Colors.blue,
    'sent': Colors.green,
    'rejected': Colors.red,
  };

  static const _statusLabels = {
    'draft': 'Draft',
    'submitted': 'Diajukan',
    'approved': 'Disetujui',
    'sent': 'Terkirim',
    'rejected': 'Ditolak',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocBuilder<LetterBloc, LetterState>(
        builder: (context, state) {
          if (state is LetterLoading || state is LetterInitial) {
            return const LoadingState(message: 'Memuat detail surat...');
          }
          if (state is LetterFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final letter = (state as LetterDetailLoaded).letter;
          final statusColor = _statusColors[letter.status] ?? Colors.grey;
          final statusLabel = _statusLabels[letter.status] ?? letter.status;

          return CustomScrollView(
            slivers: [
              // Gradient app bar
              SliverAppBar(
                expandedHeight: 178,
                pinned: true,
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                title: const Text(
                  'Detail Surat',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 70, 20, 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detail Surat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Flexible(
                                  child: _HeaderBadge(
                                    label: letter.categoryName,
                                    background: Colors.white.withValues(
                                      alpha: 0.20,
                                    ),
                                    borderColor: Colors.transparent,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: _HeaderBadge(
                                    label: statusLabel,
                                    background: statusColor.withValues(
                                      alpha: 0.25,
                                    ),
                                    borderColor: Colors.white.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (letter.number.isNotEmpty &&
                                letter.number != '-') ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.tag_rounded,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'No. ${letter.number}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              letter.subject,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            _MetaRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Dari',
                              value: letter.creatorName,
                            ),
                            const SizedBox(height: 8),
                            _MetaRow(
                              icon: Icons.business_outlined,
                              label: 'Unit',
                              value: letter.unitName,
                            ),
                            if (letter.createdAt.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _MetaRow(
                                icon: Icons.access_time_rounded,
                                label: 'Tanggal',
                                value: letter.createdAt,
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Status indicator bar
                            _StatusProgressBar(status: letter.status),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Body content
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 18,
                                  color: Color(0xFF1565C0),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Isi Surat',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              letter.body.isNotEmpty
                                  ? letter.body
                                  : '(Tidak ada isi surat)',
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      _ActionButtons(letter: letter),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.label,
    required this.background,
    required this.borderColor,
  });

  final String label;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Status Progress Bar ──────────────────────────────────────────────────────

class _StatusProgressBar extends StatelessWidget {
  const _StatusProgressBar({required this.status});

  final String status;

  static const _steps = ['draft', 'submitted', 'approved', 'sent'];
  static const _stepLabels = {
    'draft': 'Draft',
    'submitted': 'Diajukan',
    'approved': 'Disetujui',
    'sent': 'Terkirim',
  };

  @override
  Widget build(BuildContext context) {
    if (status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Text(
              'Surat ditolak',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _steps.indexOf(status);

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? const Color(0xFF1565C0)
                  : Colors.grey.shade200,
            ),
          );
        }
        // Step dot
        final stepIndex = i ~/ 2;
        final isCompleted = stepIndex <= currentIndex;
        final isCurrent = stepIndex == currentIndex;
        return Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF1565C0)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                        width: 3,
                      )
                    : null,
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              _stepLabels[_steps[stepIndex]] ?? '',
              style: TextStyle(
                fontSize: 9,
                color: isCompleted ? const Color(0xFF1565C0) : Colors.grey,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.letter});

  final dynamic letter;

  @override
  Widget build(BuildContext context) {
    return switch (letter.status) {
      'draft' => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            context.read<LetterBloc>().add(LetterSubmitted(letter.id));
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.send_rounded),
          label: const Text(
            'Ajukan Surat',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
      'submitted' => Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                context.read<LetterBloc>().add(LetterApproved(letter.id));
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_rounded),
              label: const Text(
                'Setujui',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<LetterBloc>().add(LetterRejected(letter.id));
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.close_rounded),
              label: const Text(
                'Tolak',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      _ => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            context.read<LetterBloc>().add(LetterArchived(letter.id));
            Navigator.of(context).pop();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Arsipkan Surat'),
        ),
      ),
    };
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        const Text(': ', style: TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }
}
