import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../bloc/aspiration_bloc.dart';
import '../bloc/aspiration_event.dart';
import '../bloc/aspiration_state.dart';

class AspirationDetailScreen extends StatefulWidget {
  const AspirationDetailScreen({required this.id, super.key});

  final int id;

  @override
  State<AspirationDetailScreen> createState() => _AspirationDetailScreenState();
}

class _AspirationDetailScreenState extends State<AspirationDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AspirationBloc>().add(AspirationDetailFetched(widget.id));
  }

  void _reload() {
    context.read<AspirationBloc>().add(AspirationDetailFetched(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Aspirasi')),
      body: BlocBuilder<AspirationBloc, AspirationState>(
        builder: (context, state) {
          if (state is AspirationLoading || state is AspirationInitial) {
            return const LoadingState(message: 'Memuat detail aspirasi...');
          }

          if (state is AspirationFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final aspiration = (state as AspirationDetailLoaded).aspiration;

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
                      aspiration.categoryName,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: aspiration.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                aspiration.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                [aspiration.creatorName, aspiration.createdAt].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (aspiration.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: aspiration.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                aspiration.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        context.read<AspirationBloc>().add(
                          AspirationSupportToggled(aspiration.id),
                        );
                      },
                      icon: Icon(
                        aspiration.isSupported
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                      label: Text(
                        aspiration.isSupported ? 'Didukung' : 'Dukung',
                      ),
                      style: aspiration.isSupported
                          ? FilledButton.styleFrom(
                              backgroundColor: colorScheme.error,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${aspiration.supportCount} dukungan',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
      'belum_diproses' => Colors.orange,
      'diproses' => Colors.blue,
      'selesai' => Colors.green,
      _ => Colors.grey,
    };
  }

  String _label(String status) {
    return switch (status) {
      'belum_diproses' => 'Belum diproses',
      'diproses' => 'Diproses',
      'selesai' => 'Selesai',
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
