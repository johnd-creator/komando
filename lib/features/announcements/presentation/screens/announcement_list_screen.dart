import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../data/models/announcement_model.dart';
import '../bloc/announcement_bloc.dart';
import '../bloc/announcement_event.dart';
import '../bloc/announcement_state.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AnnouncementBloc>().add(
      const AnnouncementsFetched(refresh: true),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<AnnouncementBloc>().add(
      AnnouncementsFetched(query: _searchController.text, refresh: true),
    );
  }

  void _loadMore() {
    context.read<AnnouncementBloc>().add(
      AnnouncementsFetched(query: _searchController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: BlocBuilder<AnnouncementBloc, AnnouncementState>(
        builder: (context, state) {
          if (state is AnnouncementLoading || state is AnnouncementInitial) {
            return const LoadingState(message: 'Memuat pengumuman...');
          }

          if (state is AnnouncementFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final listState = state as AnnouncementListLoaded;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount:
                  1 +
                  (listState.items.isEmpty ? 1 : listState.items.length) +
                  (listState.hasMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return SearchBar(
                    controller: _searchController,
                    hintText: 'Cari pengumuman',
                    leading: const Icon(Icons.search_rounded),
                    trailing: [
                      IconButton(
                        tooltip: 'Cari',
                        onPressed: _reload,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                    onSubmitted: (_) => _reload(),
                  );
                }

                if (listState.items.isEmpty && index == 1) {
                  return const SizedBox(
                    height: 360,
                    child: EmptyState(
                      title: 'Belum ada pengumuman',
                      message:
                          'Pengumuman aktif yang bisa Anda lihat akan tampil di sini.',
                    ),
                  );
                }

                final itemIndex = index - 1;
                if (listState.hasMore && itemIndex >= listState.items.length) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: _loadMore,
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Muat lagi'),
                    ),
                  );
                }

                return _AnnouncementCard(
                  announcement: listState.items[itemIndex],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          announcement.isPinned
              ? Icons.push_pin_rounded
              : Icons.campaign_outlined,
        ),
        title: Text(announcement.title),
        subtitle: Text(
          [
            announcement.unitName,
            if (announcement.createdAt.isNotEmpty) announcement.createdAt,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          context.push(AppRoutes.announcementDetail(announcement.id));
        },
      ),
    );
  }
}
