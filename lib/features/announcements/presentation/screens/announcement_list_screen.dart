import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../../../shared/presentation/widgets/section_header.dart';
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
  bool _showSearch = false;

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
      backgroundColor: const Color(0xFFF5F7FA),
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
            child: CustomScrollView(
              slivers: [
                // Header — uses FeaturePageHeader to avoid double-title
                FeaturePageHeader(
                  title: 'Pengumuman',
                  icon: Icons.campaign_rounded,
                  subtitle: 'Informasi resmi dari serikat',
                  actions: [
                    IconButton(
                      icon: Icon(
                        _showSearch ? Icons.close : Icons.search_rounded,
                      ),
                      tooltip: _showSearch
                          ? 'Tutup pencarian'
                          : 'Cari pengumuman',
                      onPressed: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchController.clear();
                            _reload();
                          }
                        });
                      },
                    ),
                  ],
                ),

                // Search bar (animated)
                if (_showSearch)
                  SliverToBoxAdapter(
                    child: Container(
                      color: const Color(0xFF1565C0),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Cari pengumuman...',
                          hintStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white70,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _reload();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {});
                        },
                        onSubmitted: (_) => _reload(),
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                  ),

                // Pinned announcements section
                if (listState.items.any((a) => a.isPinned)) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.push_pin_rounded,
                            size: 16,
                            color: Color(0xFF1565C0),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Dipin',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: listState.items
                          .where((a) => a.isPinned)
                          .length,
                      itemBuilder: (context, index) {
                        final pinned = listState.items
                            .where((a) => a.isPinned)
                            .toList();
                        return _AnnouncementCard(
                          announcement: pinned[index],
                          isLast: index == pinned.length - 1,
                        );
                      },
                    ),
                  ),
                ],

                // All / non-pinned section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.campaign_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          listState.items.any((a) => a.isPinned)
                              ? 'Semua Pengumuman'
                              : 'Pengumuman',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${listState.items.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (listState.items.isEmpty)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: EmptyState(
                        title: 'Belum ada pengumuman',
                        message: 'Pengumuman aktif akan tampil di sini.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.builder(
                      itemCount:
                          listState.items.length + (listState.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= listState.items.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: TextButton.icon(
                                onPressed: _loadMore,
                                icon: const Icon(Icons.expand_more_rounded),
                                label: const Text('Muat lagi'),
                              ),
                            ),
                          );
                        }
                        return _AnnouncementCard(
                          announcement: listState.items[index],
                          isLast: index == listState.items.length - 1,
                        );
                      },
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

// ─── Announcement Card ────────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, this.isLast = false});

  final AnnouncementModel announcement;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: announcement.isPinned
            ? Border.all(
                color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () =>
              context.push(AppRoutes.announcementDetail(announcement.id)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: announcement.isPinned
                        ? const Color(0xFF1565C0).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    announcement.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.campaign_outlined,
                    color: announcement.isPinned
                        ? const Color(0xFF1565C0)
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (announcement.isPinned) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Pin',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (announcement.body.isNotEmpty)
                        Text(
                          announcement.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.business_outlined,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              announcement.unitName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (announcement.createdAt.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              announcement.createdAt.length > 10
                                  ? announcement.createdAt.substring(0, 10)
                                  : announcement.createdAt,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      if (announcement.attachments.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 13,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${announcement.attachments.length} lampiran',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
