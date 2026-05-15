import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
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

class _AnnouncementListScreenState extends State<AnnouncementListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _showSearch = false;
  late final AnimationController _searchAnimController;
  late final Animation<double> _searchAnimation;

  @override
  void initState() {
    super.initState();
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeInOut,
    );
    context.read<AnnouncementBloc>().add(
      const AnnouncementsFetched(refresh: true),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimController.dispose();
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

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (_showSearch) {
        _searchAnimController.forward();
      } else {
        _searchController.clear();
        _searchAnimController.reverse();
        _reload();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<AnnouncementBloc, AnnouncementState>(
        builder: (context, state) {
          if (state is AnnouncementLoading || state is AnnouncementInitial) {
            return const LoadingState(message: 'Memuat pengumuman...');
          }
          if (state is AnnouncementFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final listState = state as AnnouncementListLoaded;
          final pinnedItems = listState.items.where((a) => a.isPinned).toList();
          final allItems = listState.items;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                FeaturePageHeader(
                  title: 'Pengumuman',
                  icon: Icons.campaign_rounded,
                  subtitle: 'Informasi resmi dari serikat',
                  actions: [
                    IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          _showSearch
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          key: ValueKey(_showSearch),
                        ),
                      ),
                      tooltip: _showSearch
                          ? 'Tutup pencarian'
                          : 'Cari pengumuman',
                      onPressed: _toggleSearch,
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: SizeTransition(
                    sizeFactor: _searchAnimation,
                    axisAlignment: -1,
                    child: Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Cari pengumuman...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Colors.white60,
                              size: 22,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _reload();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (v) => setState(() {}),
                          onSubmitted: (_) => _reload(),
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                    ),
                  ),
                ),

                if (pinnedItems.isNotEmpty) ...[
                  const _SectionLabel(
                    icon: Icons.push_pin_rounded,
                    label: 'Dipin',
                    color: AppColors.primary,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: pinnedItems.length,
                      itemBuilder: (context, index) => _AnnouncementCard(
                        announcement: pinnedItems[index],
                        isLast: index == pinnedItems.length - 1,
                      ),
                    ),
                  ),
                ],

                _SectionLabel(
                  icon: Icons.campaign_outlined,
                  label: pinnedItems.isNotEmpty
                      ? 'Semua Pengumuman'
                      : 'Pengumuman',
                  count: allItems.length,
                ),

                if (allItems.isEmpty)
                  const SliverToBoxAdapter(child: _EmptyAnnouncementState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.builder(
                      itemCount: allItems.length + (listState.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= allItems.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: OutlinedButton.icon(
                                onPressed: _loadMore,
                                icon: const Icon(
                                  Icons.expand_more_rounded,
                                  size: 18,
                                ),
                                label: const Text('Muat lebih banyak'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return _AnnouncementCard(
                          announcement: allItems[index],
                          isLast: index == allItems.length - 1,
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyAnnouncementState extends StatelessWidget {
  const _EmptyAnnouncementState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.06),
                    ),
                  ),
                  // Secondary circle
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // Main icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  // Small decorative dot
                  Positioned(
                    left: 12,
                    bottom: 20,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada pengumuman',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pengumuman aktif akan tampil di sini.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    this.color = Colors.grey,
    this.count,
  });

  final IconData icon;
  final String label;
  final Color color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            // Decorative left bar
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
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
    final isPinned = announcement.isPinned;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: isPinned ? const Color(0xFFF0F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isPinned
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            spreadRadius: isPinned ? 1 : 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              context.push(AppRoutes.announcementDetail(announcement.id)),
          child: Stack(
            children: [
              // Pinned ribbon indicator (top-right corner)
              if (isPinned)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: const Icon(
                      Icons.push_pin_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left border — thicker gradient for pinned
                    Container(
                      width: isPinned ? 5 : 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isPinned
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                              )
                            : null,
                        color: isPinned ? null : Colors.grey.shade300,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
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
                                      color: AppColors.textPrimary,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPinned) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.push_pin_rounded,
                                          size: 11,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Pin',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (announcement.body.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                announcement.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                  height: 1.45,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            // Meta chips in a grouped container
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  _MetaChip(
                                    Icons.business_outlined,
                                    announcement.unitName,
                                  ),
                                  if (announcement.createdAt.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    _MetaChip(
                                      Icons.access_time_rounded,
                                      announcement.createdAt.length > 10
                                          ? announcement.createdAt.substring(
                                              0,
                                              10,
                                            )
                                          : announcement.createdAt,
                                    ),
                                  ],
                                  if (announcement.attachments.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    _MetaChip(
                                      Icons.attach_file_rounded,
                                      '${announcement.attachments.length}',
                                    ),
                                  ],
                                  const Spacer(),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Meta Chip ────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
