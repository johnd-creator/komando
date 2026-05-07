import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../data/models/aspiration_model.dart';
import '../bloc/aspiration_bloc.dart';
import '../bloc/aspiration_event.dart';
import '../bloc/aspiration_state.dart';

class AspirationListScreen extends StatefulWidget {
  const AspirationListScreen({super.key});

  @override
  State<AspirationListScreen> createState() => _AspirationListScreenState();
}

class _AspirationListScreenState extends State<AspirationListScreen> {
  String? _category;
  String? _status;
  String? _sort;

  void _reload() {
    context.read<AspirationBloc>().add(
      AspirationsFetched(category: _category, status: _status, sort: _sort, refresh: true),
    );
  }

  void _loadMore() {
    context.read<AspirationBloc>().add(
      AspirationsFetched(category: _category, status: _status, sort: _sort),
    );
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aspirasi'),
        actions: [
          IconButton(
            tooltip: 'Filter',
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.aspirationCreate);
          _reload();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat'),
      ),
      body: BlocBuilder<AspirationBloc, AspirationState>(
        builder: (context, state) {
          if (state is AspirationLoading || state is AspirationInitial) {
            return const LoadingState(message: 'Memuat aspirasi...');
          }

          if (state is AspirationFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final listState = state as AspirationListLoaded;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount:
                  (listState.items.isEmpty ? 1 : listState.items.length) +
                  (listState.hasMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (listState.items.isEmpty && index == 0) {
                  return const SizedBox(
                    height: 400,
                    child: EmptyState(
                      title: 'Belum ada aspirasi',
                      message: 'Belum ada aspirasi yang dikirim. Gunakan tombol Buat untuk mengirim aspirasi pertama Anda.',
                    ),
                  );
                }

                if (listState.hasMore && index >= listState.items.length) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: _loadMore,
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Muat lagi'),
                    ),
                  );
                }

                return _AspirationCard(aspiration: listState.items[index]);
              },
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Urutkan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua')),
                DropdownMenuItem(value: 'fasilitas', child: Text('Fasilitas')),
                DropdownMenuItem(value: 'pelayanan', child: Text('Pelayanan')),
                DropdownMenuItem(value: 'kesejahteraan', child: Text('Kesejahteraan')),
                DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
              ],
              onChanged: (value) {
                _category = value;
                Navigator.pop(context);
                _reload();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua')),
                DropdownMenuItem(value: 'belum_diproses', child: Text('Belum diproses')),
                DropdownMenuItem(value: 'diproses', child: Text('Diproses')),
                DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
              ],
              onChanged: (value) {
                _status = value;
                Navigator.pop(context);
                _reload();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sort,
              decoration: const InputDecoration(
                labelText: 'Urutkan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sort_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'latest', child: Text('Terbaru')),
                DropdownMenuItem(value: 'popular', child: Text('Populer')),
              ],
              onChanged: (value) {
                _sort = value;
                Navigator.pop(context);
                _reload();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AspirationCard extends StatelessWidget {
  const _AspirationCard({required this.aspiration});

  final AspirationModel aspiration;

  Color _statusColor(String status) {
    return switch (status) {
      'belum_diproses' => Colors.orange,
      'diproses' => Colors.blue,
      'selesai' => Colors.green,
      _ => Colors.grey,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'belum_diproses' => 'Belum diproses',
      'diproses' => 'Diproses',
      'selesai' => 'Selesai',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(aspiration.categoryName.characters.first.toUpperCase()),
        ),
        title: Text(aspiration.title),
        subtitle: Text(
          [
            aspiration.creatorName,
            aspiration.createdAt,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(aspiration.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _statusLabel(aspiration.status),
                    style: TextStyle(fontSize: 11, color: _statusColor(aspiration.status)),
                  ),
                ),
                if (aspiration.supportCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${aspiration.supportCount} dukungan',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () => context.push(AppRoutes.aspirationDetail(aspiration.id)),
      ),
    );
  }
}
