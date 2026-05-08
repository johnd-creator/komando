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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Surat')),
      body: BlocBuilder<LetterBloc, LetterState>(
        builder: (context, state) {
          if (state is LetterLoading || state is LetterInitial) {
            return const LoadingState(message: 'Memuat detail surat...');
          }

          if (state is LetterFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final letter = (state as LetterDetailLoaded).letter;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      letter.categoryName,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: letter.status),
                ],
              ),
              if (letter.number.isNotEmpty && letter.number != '-') ...[
                const SizedBox(height: 8),
                Text(
                  'No. ${letter.number}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colorScheme.outline),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                letter.subject,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  letter.creatorName,
                  letter.unitName,
                  letter.createdAt,
                ].where((e) => e.isNotEmpty && e != '-').join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text(letter.body, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              if (letter.status == 'draft') ...[
                FilledButton.icon(
                  onPressed: () {
                    context.read<LetterBloc>().add(LetterSubmitted(letter.id));
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Ajukan Surat'),
                ),
              ],
              if (letter.status == 'submitted') ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          context.read<LetterBloc>().add(
                            LetterApproved(letter.id),
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        label: const Text('Setujui'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<LetterBloc>().add(
                            LetterRejected(letter.id),
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        label: const Text('Tolak'),
                      ),
                    ),
                  ],
                ),
              ],
              if (letter.status != 'draft' && letter.status != 'submitted')
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<LetterBloc>().add(LetterArchived(letter.id));
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Arsipkan'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  Color _color(String status) {
    return switch (status) {
      'draft' => Colors.grey,
      'submitted' => Colors.orange,
      'approved' => Colors.blue,
      'sent' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };
  }

  String _label(String status) {
    return switch (status) {
      'draft' => 'Draft',
      'submitted' => 'Diajukan',
      'approved' => 'Disetujui',
      'sent' => 'Terkirim',
      'rejected' => 'Ditolak',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          fontSize: 11,
          color: _color(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
