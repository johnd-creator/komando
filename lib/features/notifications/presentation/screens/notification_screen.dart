import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const NotificationsFetched());
  }

  void _reload() {
    context.read<NotificationBloc>().add(const NotificationsFetched());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () {
              context
                  .read<NotificationBloc>()
                  .add(const NotificationsReadAllRequested());
            },
            child: const Text('Tandai semua'),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const LoadingState(message: 'Memuat notifikasi...');
          }

          if (state is NotificationFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final page = (state as NotificationLoaded).page;
          if (page.items.isEmpty) {
            return const EmptyState(
              title: 'Belum ada notifikasi',
              message: 'Notifikasi anggota akan tampil di sini.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: page.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = page.items[index];
                return Card(
                  elevation: notification.isRead ? 0 : 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (!notification.isRead) {
                        context.read<NotificationBloc>().add(
                          NotificationReadRequested(notification.id),
                        );
                      }
                      _navigateToFeature(context, notification);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NotificationDot(isRead: notification.isRead),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _CategoryChip(category: notification.category),
                                    const Spacer(),
                                    Text(
                                      _formatRelative(notification.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(notification.message),
                                if (notification.link != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ketuk untuk detail',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatRelative(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  void _navigateToFeature(BuildContext context, dynamic notification) {
    if (notification.link != null) {
      final link = notification.link as String;
      if (link.startsWith('/')) {
        context.push(link);
        return;
      }
    }

    final route = switch (notification.category) {
      'announcement' => AppRoutes.announcements,
      'aspiration' => AppRoutes.aspirations,
      'letter' => AppRoutes.letters,
      'finance' => AppRoutes.keuangan,
      'dues' => AppRoutes.iuran,
      'membership' => '/kta',
      _ => null,
    };

    if (route != null) {
      context.push(route);
    }
  }
}

class _NotificationDot extends StatelessWidget {
  const _NotificationDot({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isRead
            ? Colors.transparent
            : Theme.of(context).colorScheme.primary,
        border: isRead
            ? Border.all(color: Theme.of(context).colorScheme.outline)
            : null,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _chipColor(category).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _chipColor(category),
        ),
      ),
    );
  }

  Color _chipColor(String category) {
    return switch (category) {
      'announcement' => Colors.blue,
      'aspiration' => Colors.orange,
      'letter' => Colors.purple,
      'finance' => Colors.teal,
      'dues' => Colors.green,
      'membership' => Colors.indigo,
      _ => Colors.blueGrey,
    };
  }
}
