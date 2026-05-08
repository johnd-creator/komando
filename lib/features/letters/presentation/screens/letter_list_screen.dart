import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../data/models/letter_model.dart';
import '../bloc/letter_bloc.dart';
import '../bloc/letter_event.dart';
import '../bloc/letter_state.dart';

const _boxLabels = {
  'inbox': 'Masuk',
  'outbox': 'Keluar',
  'approvals': 'Approval',
};

const _boxIcons = {
  'inbox': Icons.move_to_inbox_rounded,
  'outbox': Icons.outbox_rounded,
  'approvals': Icons.approval_rounded,
};

class LetterListScreen extends StatefulWidget {
  const LetterListScreen({this.initialBox = 'inbox', super.key});

  final String initialBox;

  @override
  State<LetterListScreen> createState() => _LetterListScreenState();
}

class _LetterListScreenState extends State<LetterListScreen> {
  late String _box;

  @override
  void initState() {
    super.initState();
    _box = widget.initialBox;
    _reload();
  }

  void _reload() {
    context.read<LetterBloc>().add(LettersFetched(box: _box, refresh: true));
  }

  void _loadMore() {
    context.read<LetterBloc>().add(LettersFetched(box: _box));
  }

  void _switchBox(String box) {
    setState(() => _box = box);
    context.read<LetterBloc>().add(LetterBoxChanged(box));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Surat')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.letterCreate);
          _reload();
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Buat'),
      ),
      body: Column(
        children: [
          _TabBar(activeBox: _box, onChanged: _switchBox),
          Expanded(
            child: BlocBuilder<LetterBloc, LetterState>(
              builder: (context, state) {
                if (state is LetterLoading || state is LetterInitial) {
                  return const LoadingState(message: 'Memuat surat...');
                }

                if (state is LetterFailure) {
                  return ErrorState(message: state.message, onRetry: _reload);
                }

                final listState = state as LetterListLoaded;

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        (listState.items.isEmpty ? 1 : listState.items.length) +
                        (listState.hasMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (listState.items.isEmpty && index == 0) {
                        return SizedBox(
                          height: 400,
                          child: EmptyState(
                            title: _emptyTitle,
                            message: _emptyMessage,
                          ),
                        );
                      }

                      if (listState.hasMore &&
                          index >= listState.items.length) {
                        return Center(
                          child: TextButton.icon(
                            onPressed: _loadMore,
                            icon: const Icon(Icons.expand_more_rounded),
                            label: const Text('Muat lagi'),
                          ),
                        );
                      }

                      return _LetterCard(letter: listState.items[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String get _emptyTitle {
    return switch (_box) {
      'inbox' => 'Belum ada surat masuk',
      'outbox' => 'Belum ada surat keluar',
      'approvals' => 'Belum ada surat perlu approval',
      _ => 'Belum ada surat',
    };
  }

  String get _emptyMessage {
    return switch (_box) {
      'inbox' => 'Surat yang dikirim kepada Anda akan tampil di sini.',
      'outbox' => 'Gunakan tombol Buat untuk membuat surat baru.',
      'approvals' => 'Surat yang perlu Anda setujui akan tampil di sini.',
      _ => 'Belum ada surat.',
    };
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.activeBox, required this.onChanged});

  final String activeBox;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final box in _boxLabels.keys)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: box == _boxLabels.keys.last ? 0 : 8,
                ),
                child: FilterChip(
                  selected: activeBox == box,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_boxIcons[box]!, size: 18),
                      const SizedBox(width: 6),
                      Text(_boxLabels[box]!),
                    ],
                  ),
                  onSelected: (_) => onChanged(box),
                  showCheckmark: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({required this.letter});

  final LetterModel letter;

  Color _statusColor(String status) {
    return switch (status) {
      'draft' => Colors.grey,
      'submitted' => Colors.orange,
      'approved' => Colors.blue,
      'sent' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.grey,
    };
  }

  String _statusLabel(String status) {
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            letter.hasAttachments
                ? Icons.attach_file_rounded
                : Icons.mail_outline_rounded,
            size: 20,
          ),
        ),
        title: Text(letter.subject),
        subtitle: Text(
          [letter.creatorName, letter.createdAt].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _statusColor(letter.status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _statusLabel(letter.status),
            style: TextStyle(
              fontSize: 11,
              color: _statusColor(letter.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => context.push(AppRoutes.letterDetail(letter.id)),
      ),
    );
  }
}
