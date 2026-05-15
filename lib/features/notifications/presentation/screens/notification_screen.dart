import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../../../shared/presentation/notifiers/bottom_nav_notifier.dart';
import '../../data/models/notification_model.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_empty_state.dart';
import '../widgets/notification_group_card.dart';
import '../widgets/notification_list.dart';
import '../widgets/notification_section_header.dart';
import '../widgets/notification_top_section.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedCategory = 'all';

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
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const LoadingState(message: 'Memuat notifikasi...');
          }

          if (state is NotificationFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final page = (state as NotificationLoaded).page;
          final filteredItems = _filteredItems(page.items);
          final unreadItems = filteredItems
              .where((item) => !item.isRead)
              .toList();
          final readItems = filteredItems.where((item) => item.isRead).toList();

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: NotificationTopSection(
                    selectedCategory: _selectedCategory,
                    onSelected: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ),
                if (filteredItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: NotificationEmptyState(
                      selectedCategory: _selectedCategory,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 110),
                    sliver: SliverList.list(
                      children: [
                        if (unreadItems.isNotEmpty) ...[
                          NotificationSectionHeader(
                            title: 'Belum dibaca',
                            count: unreadItems.length,
                            trailing: TextButton(
                              onPressed: () {
                                context.read<NotificationBloc>().add(
                                  const NotificationsReadAllRequested(),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF0967D8),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Tandai semua dibaca'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          NotificationGroupCard(
                            items: unreadItems,
                            onTap: _openNotification,
                          ),
                          const SizedBox(height: 22),
                        ],
                        if (readItems.isNotEmpty) ...[
                          const NotificationSectionHeader(title: 'Sebelumnya'),
                          const SizedBox(height: 12),
                          NotificationList(
                            items: readItems,
                            onTap: _openNotification,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<NotificationModel> _filteredItems(List<NotificationModel> items) {
    if (_selectedCategory == 'all') return items;
    return items.where((item) {
      final category = item.category.toLowerCase();
      final type = item.type.toLowerCase();
      return category == _selectedCategory || type == _selectedCategory;
    }).toList();
  }

  void _openNotification(NotificationModel notification) {
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        NotificationReadRequested(notification.id),
      );
    }
    _navigateToFeature(context, notification);
  }

  void _navigateToFeature(
    BuildContext context,
    NotificationModel notification,
  ) {
    final link = notification.link;
    final route = link == null ? null : _mobileRouteFromLink(link);
    if (route != null) {
      _openRoute(context, route);
      return;
    }

    if (_openShellTabFromLink(context, link)) {
      return;
    }

    // Fallback berdasarkan kategori
    final category = notification.category.toLowerCase();
    final type = notification.type.toLowerCase();

    // Coba match kategori
    if (category.contains('announcement') ||
        category.contains('pengumuman') ||
        type.contains('announcement') ||
        type.contains('pengumuman')) {
      _openRoute(context, AppRoutes.announcements);
    } else if (category.contains('aspiration') ||
        category.contains('aspirasi') ||
        type.contains('aspiration') ||
        type.contains('aspirasi')) {
      _openRoute(context, AppRoutes.aspirations);
    } else if (category.contains('letter') ||
        category.contains('surat') ||
        type.contains('letter') ||
        type.contains('surat')) {
      _openRoute(context, AppRoutes.letters);
    } else if (category.contains('finance') ||
        category.contains('keuangan') ||
        type.contains('finance') ||
        type.contains('keuangan')) {
      _openRoute(context, AppRoutes.keuangan);
    } else if (category.contains('dues') ||
        category.contains('iuran') ||
        type.contains('dues') ||
        type.contains('iuran')) {
      _openRoute(context, AppRoutes.iuran);
    } else if (category.contains('membership') ||
        category.contains('kta') ||
        type.contains('membership') ||
        type.contains('kta')) {
      _openRoute(context, AppRoutes.kta);
    } else if (category.contains('news') ||
        category.contains('berita') ||
        type.contains('news') ||
        type.contains('berita')) {
      _openRoute(context, AppRoutes.news);
    } else {
      BottomNavScope.of(context).goToTab(0);
    }
  }

  void _openRoute(BuildContext context, String route) {
    if (route == AppRoutes.home) {
      context.go(route);
      return;
    }
    context.push(route);
  }

  bool _openShellTabFromLink(BuildContext context, String? link) {
    final route = _normalizedPath(link);
    if (route == null) return false;

    if (route == AppRoutes.notifications) {
      BottomNavScope.of(context).goToTab(2);
      return true;
    }
    if (route == '/profile' || route == '/member/profile') {
      BottomNavScope.of(context).goToTab(3);
      return true;
    }
    if (route == '/member/portal') {
      BottomNavScope.of(context).goToTab(0);
      return true;
    }

    return false;
  }

  String? _mobileRouteFromLink(String link) {
    final path = _normalizedPath(link);
    if (path == null) return null;

    final exactRoutes = <String, String>{
      '/': AppRoutes.home,
      '/home': AppRoutes.home,
      '/dashboard': AppRoutes.home,
      '/announcements': AppRoutes.announcements,
      '/pengumuman': AppRoutes.announcements,
      '/aspirations': AppRoutes.aspirations,
      '/aspirasi': AppRoutes.aspirations,
      '/letters': AppRoutes.letters,
      '/surat': AppRoutes.letters,
      '/finance': AppRoutes.keuangan,
      '/finance/ledgers': AppRoutes.keuangan,
      '/keuangan': AppRoutes.keuangan,
      '/dues': AppRoutes.iuran,
      '/iuran': AppRoutes.iuran,
      '/member/card': AppRoutes.kta,
      '/kta': AppRoutes.kta,
      '/news': AppRoutes.news,
      '/berita': AppRoutes.news,
    };
    final exactRoute = exactRoutes[path];
    if (exactRoute != null) return exactRoute;

    final detailPatterns = <RegExp, String Function(int)>{
      RegExp(r'^/announcements/(\d+)$'): AppRoutes.announcementDetail,
      RegExp(r'^/pengumuman/(\d+)$'): AppRoutes.announcementDetail,
      RegExp(r'^/aspirations/(\d+)$'): AppRoutes.aspirationDetail,
      RegExp(r'^/aspirasi/(\d+)$'): AppRoutes.aspirationDetail,
      RegExp(r'^/admin/aspirations/(\d+)$'): AppRoutes.aspirationDetail,
      RegExp(r'^/letters/(\d+)$'): AppRoutes.letterDetail,
      RegExp(r'^/surat/(\d+)$'): AppRoutes.letterDetail,
      RegExp(r'^/finance/ledgers/(\d+)$'): AppRoutes.financeLedgerDetail,
    };

    for (final entry in detailPatterns.entries) {
      final match = entry.key.firstMatch(path);
      if (match == null) continue;
      final id = int.tryParse(match.group(1) ?? '');
      if (id != null && id > 0) return entry.value(id);
    }

    return null;
  }

  String? _normalizedPath(String? link) {
    final trimmed = link?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    final path = uri?.hasScheme == true ? uri!.path : trimmed.split('?').first;
    if (path.isEmpty || !path.startsWith('/')) return null;

    final normalized = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
    return normalized;
  }
}
