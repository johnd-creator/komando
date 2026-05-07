import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../data/models/announcement_model.dart';
import '../bloc/announcement_bloc.dart';
import '../bloc/announcement_event.dart';
import '../bloc/announcement_state.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  const AnnouncementDetailScreen({required this.id, super.key});

  final int id;

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AnnouncementBloc>().add(AnnouncementDetailFetched(widget.id));
  }

  void _reload() {
    context.read<AnnouncementBloc>().add(AnnouncementDetailFetched(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengumuman')),
      body: BlocBuilder<AnnouncementBloc, AnnouncementState>(
        builder: (context, state) {
          if (state is AnnouncementLoading || state is AnnouncementInitial) {
            return const LoadingState(message: 'Memuat detail pengumuman...');
          }

          if (state is AnnouncementFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final announcement = (state as AnnouncementDetailLoaded).announcement;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  if (announcement.isPinned) ...[
                    const Icon(Icons.push_pin_rounded, size: 18),
                    const SizedBox(width: 6),
                    const Text('Dipin'),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      announcement.unitName,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                announcement.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  if (announcement.creatorName != '-') announcement.creatorName,
                  if (announcement.createdAt.isNotEmpty) announcement.createdAt,
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text(
                announcement.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (announcement.attachments.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Lampiran',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final attachment in announcement.attachments)
                  _AttachmentTile(attachment: attachment),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AnnouncementBloc>().add(
                    AnnouncementDismissRequested(announcement.id),
                  );
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.visibility_off_outlined),
                label: const Text('Sembunyikan pengumuman'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final AnnouncementAttachmentModel attachment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.attach_file_rounded),
        title: Text(attachment.originalName),
        subtitle: Text(
          attachment.mime.isEmpty ? '${attachment.size} byte' : attachment.mime,
        ),
      ),
    );
  }
}
