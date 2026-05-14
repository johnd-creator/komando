import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../../../shared/presentation/widgets/section_header.dart';
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
  final _searchController = TextEditingController();
  String? _status;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<AspirationBloc>().add(
      AspirationsFetched(status: _status, sort: null, refresh: true),
    );
  }

  void _loadMore() {
    context.read<AspirationBloc>().add(
      AspirationsFetched(status: _status, sort: null),
    );
  }

  void _selectStatus(String? status) {
    if (_status == status) return;
    setState(() => _status = status);
    _reload();
  }

  Future<void> _openCreate() async {
    await context.push(AppRoutes.aspirationCreate);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Buat Aspirasi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
          final visibleItems = _visibleItems(listState.items);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                // ── Header (same style as Iuran) ──────────────────────
                const FeaturePageHeader(
                  title: 'Aspirasi',
                  icon: Icons.chat_bubble_outline_rounded,
                  subtitle: 'Sampaikan aspirasi untuk kemajuan bersama',
                ),

                // ── Filter & Search card ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _FilterCard(
                      searchController: _searchController,
                      selectedStatus: _status,
                      onSearchChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                      onStatusSelected: _selectStatus,
                    ),
                  ),
                ),

                // ── List ──────────────────────────────────────────────
                if (visibleItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(query: _query),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    sliver: SliverList.builder(
                      itemCount:
                          visibleItems.length + (listState.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= visibleItems.length) {
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
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == visibleItems.length - 1 ? 0 : 12,
                          ),
                          child: _AspirationCard(
                            aspiration: visibleItems[index],
                          ),
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

  List<AspirationModel> _visibleItems(List<AspirationModel> items) {
    if (_query.isEmpty) return items;
    return items.where((item) {
      return item.title.toLowerCase().contains(_query) ||
          item.body.toLowerCase().contains(_query) ||
          item.categoryName.toLowerCase().contains(_query);
    }).toList();
  }
}

// ─── Filter Card ──────────────────────────────────────────────────────────────

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.searchController,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusSelected,
  });

  final TextEditingController searchController;
  final String? selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari aspirasi...',
              hintStyle: const TextStyle(color: Color(0xFFA4AEC0)),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF64748B),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1565C0),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusChip(
                label: 'Semua',
                selected: selectedStatus == null,
                onTap: () => onStatusSelected(null),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: 'Diproses',
                selected: selectedStatus == 'in_progress',
                onTap: () => onStatusSelected('in_progress'),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: 'Selesai',
                selected: selectedStatus == 'resolved',
                onTap: () => onStatusSelected('resolved'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1565C0) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF1565C0) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ─── Aspiration Card ──────────────────────────────────────────────────────────

class _AspirationCard extends StatelessWidget {
  const _AspirationCard({required this.aspiration});

  final AspirationModel aspiration;

  @override
  Widget build(BuildContext context) {
    final visual = _AspirationVisual.from(aspiration.categoryName);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          onTap: () => context.push(AppRoutes.aspirationDetail(aspiration.id)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(visual.icon, color: visual.foreground, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              aspiration.title,
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
                          const SizedBox(width: 8),
                          _StatusPill(status: aspiration.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aspiration.categoryName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        aspiration.body,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF566780),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(aspiration.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.favorite_border_rounded,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${aspiration.supportCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
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

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF1565C0),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty ? 'Belum ada aspirasi' : 'Aspirasi tidak ditemukan',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan tombol Buat Aspirasi untuk mengirim masukan baru.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final meta = _StatusMeta.from(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: meta.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          fontSize: 11,
          color: meta.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AspirationVisual {
  const _AspirationVisual({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  factory _AspirationVisual.from(String category) {
    final n = category.toLowerCase();
    if (n.contains('fasilitas')) {
      return const _AspirationVisual(
        icon: Icons.hub_outlined,
        foreground: Color(0xFF1565C0),
        background: Color(0xFFEAF4FF),
      );
    }
    if (n.contains('teknologi') || n.contains('aplikasi')) {
      return const _AspirationVisual(
        icon: Icons.desktop_windows_outlined,
        foreground: Color(0xFFD69200),
        background: Color(0xFFFFF4D9),
      );
    }
    if (n.contains('lingkungan')) {
      return const _AspirationVisual(
        icon: Icons.eco_outlined,
        foreground: Color(0xFF15803D),
        background: Color(0xFFE6F7EA),
      );
    }
    if (n.contains('kesehatan') || n.contains('kesejahteraan')) {
      return const _AspirationVisual(
        icon: Icons.favorite_border_rounded,
        foreground: Color(0xFF5134D4),
        background: Color(0xFFF0ECFF),
      );
    }
    return const _AspirationVisual(
      icon: Icons.chat_bubble_outline_rounded,
      foreground: Color(0xFF5134D4),
      background: Color(0xFFF0ECFF),
    );
  }
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  factory _StatusMeta.from(String status) {
    return switch (status) {
      'belum_diproses' => const _StatusMeta(
        label: 'Baru',
        foreground: Color(0xFF1565C0),
        background: Color(0xFFEAF4FF),
      ),
      'diproses' || 'in_progress' => const _StatusMeta(
        label: 'Diproses',
        foreground: Color(0xFFC27803),
        background: Color(0xFFFFF4D9),
      ),
      'selesai' || 'resolved' => const _StatusMeta(
        label: 'Selesai',
        foreground: Color(0xFF15803D),
        background: Color(0xFFE6F7EA),
      ),
      _ => _StatusMeta(
        label: status,
        foreground: const Color(0xFF64748B),
        background: const Color(0xFFF1F5F9),
      ),
    };
  }
}
