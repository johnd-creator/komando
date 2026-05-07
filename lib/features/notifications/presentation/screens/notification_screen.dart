import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      appBar: AppBar(title: const Text('Notifikasi')),
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
                  child: ListTile(
                    leading: Icon(
                      notification.isRead
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_rounded,
                    ),
                    title: Text(notification.title),
                    subtitle: Text(
                      notification.body.isEmpty
                          ? notification.createdAt
                          : notification.body,
                    ),
                    trailing: notification.isRead
                        ? null
                        : IconButton(
                            tooltip: 'Tandai dibaca',
                            onPressed: () {
                              context.read<NotificationBloc>().add(
                                NotificationReadRequested(notification.id),
                              );
                            },
                            icon: const Icon(Icons.done_rounded),
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
}
