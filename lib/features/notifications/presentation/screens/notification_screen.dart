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
                  child: _NotificationTopSection(
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
                    child: _NotificationEmptyState(
                      selectedCategory: _selectedCategory,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 110),
                    sliver: SliverList.list(
                      children: [
                        if (unreadItems.isNotEmpty) ...[
                          _SectionHeader(
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
                          _NotificationGroupCard(
                            items: unreadItems,
                            onTap: _openNotification,
                          ),
                          const SizedBox(height: 22),
                        ],
                        if (readItems.isNotEmpty) ...[
                          _SectionHeader(title: 'Sebelumnya'),
                          const SizedBox(height: 12),
                          _NotificationList(
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

class _NotificationTopSection extends StatelessWidget {
  const _NotificationTopSection({
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _NotificationHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 258, 14, 0),
          child: _NotificationFilterPanel(
            selectedCategory: selectedCategory,
            onSelected: onSelected,
          ),
        ),
      ],
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 328,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/bg-asset.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0069D7).withValues(alpha: 0.88),
                  const Color(0xFF075EC4).withValues(alpha: 0.80),
                  const Color(0xFF064FA8).withValues(alpha: 0.90),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F9FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Badge(
                      smallSize: 10,
                      backgroundColor: const Color(0xFFFFC928),
                      child: IconButton(
                        onPressed: () {},
                        tooltip: 'Notifikasi',
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.42),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Image.asset(
                          'assets/logo.png',
                          width: 74,
                          height: 74,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1Komando',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Serikat Pekerja PLN IP Services',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          '',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
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
    );
  }
}

class _NotificationFilterPanel extends StatelessWidget {
  const _NotificationFilterPanel({
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  static const _filters = [
    _NotificationFilter('all', 'Semua', Icons.apps_rounded),
    _NotificationFilter('system', 'Sistem', Icons.settings_outlined),
    _NotificationFilter('finance', 'Keuangan', Icons.paid_outlined),
    _NotificationFilter('aspiration', 'Aspirasi', Icons.chat_bubble_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A4667).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in _filters) ...[
              _FilterChipButton(
                filter: filter,
                selected: selectedCategory == filter.value,
                onTap: () => onSelected(filter.value),
              ),
              if (filter != _filters.last) const SizedBox(width: 9),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _NotificationFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF0967D8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? primary : const Color(0xFFE1E8F2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filter.value != 'all') ...[
                Icon(
                  filter.icon,
                  size: 20,
                  color: selected ? Colors.white : _categoryColor(filter.value),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                filter.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? Colors.white : const Color(0xFF17243D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count, this.trailing});

  final String title;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF0B1B37),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0967D8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _NotificationGroupCard extends StatelessWidget {
  const _NotificationGroupCard({required this.items, required this.onTap});

  final List<NotificationModel> items;
  final ValueChanged<NotificationModel> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A4667).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _NotificationTile(notification: items[index], onTap: onTap),
            if (index != items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 86, right: 14),
                child: Divider(height: 1, color: Color(0xFFE0E7F0)),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.items, required this.onTap});

  final List<NotificationModel> items;
  final ValueChanged<NotificationModel> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7EDF6)),
            ),
            child: _NotificationTile(notification: item, onTap: onTap),
          ),
          if (item != items.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final ValueChanged<NotificationModel> onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _NotificationVisual.from(notification);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(notification),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                child: _UnreadDot(isRead: notification.isRead),
              ),
              const SizedBox(width: 10),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: meta.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(meta.icon, color: meta.foreground, size: 31),
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
                            _titleFor(notification),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: const Color(0xFF0B1B37),
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF51617A),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF50617B),
                        height: 1.34,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.blueGrey.shade300,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(NotificationModel notification) {
    final message = notification.message.trim();
    if (message.isEmpty) return _categoryLabel(notification.category);

    final separators = ['\n', '.', ':', '-'];
    var end = message.length;
    for (final separator in separators) {
      final index = message.indexOf(separator);
      if (index > 8 && index < end) end = index;
    }

    final title = message.substring(0, end).trim();
    if (title.length > 46) return _categoryLabel(notification.category);
    return title;
  }

  String _formatTime(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 1) return 'Kemarin';
      if (diff.inDays > 1) return '${date.day}/${date.month}/${date.year}';
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return isoDate;
    }
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isRead ? 0 : 1,
      duration: const Duration(milliseconds: 160),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFF0967D8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState({required this.selectedCategory});

  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    final label = selectedCategory == 'all'
        ? 'notifikasi'
        : _categoryLabel(selectedCategory).toLowerCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF0967D8),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada $label',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF0B1B37),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi anggota akan tampil di sini.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _NotificationFilter {
  const _NotificationFilter(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  factory _NotificationVisual.from(NotificationModel notification) {
    final category = notification.category.toLowerCase();
    final type = notification.type.toLowerCase();

    if (category == 'finance' || category == 'dues' || type == 'finance') {
      return const _NotificationVisual(
        icon: Icons.monetization_on_outlined,
        foreground: Color(0xFF0B7A35),
        background: Color(0xFFEAF7EC),
      );
    }
    if (category == 'aspiration' || type == 'aspiration') {
      return const _NotificationVisual(
        icon: Icons.chat_bubble_outline_rounded,
        foreground: Color(0xFF5134D4),
        background: Color(0xFFF0ECFF),
      );
    }
    if (category == 'letter' || type == 'letter') {
      return const _NotificationVisual(
        icon: Icons.mail_outline_rounded,
        foreground: Color(0xFFC27803),
        background: Color(0xFFFFF7E6),
      );
    }
    if (category == 'announcement') {
      return const _NotificationVisual(
        icon: Icons.event_note_outlined,
        foreground: Color(0xFF0967D8),
        background: Color(0xFFEAF4FF),
      );
    }
    if (category == 'membership') {
      return const _NotificationVisual(
        icon: Icons.badge_outlined,
        foreground: Color(0xFF0967D8),
        background: Color(0xFFEAF4FF),
      );
    }
    return const _NotificationVisual(
      icon: Icons.settings_outlined,
      foreground: Color(0xFF64748B),
      background: Color(0xFFF1F5F9),
    );
  }
}

Color _categoryColor(String category) {
  return switch (category) {
    'finance' || 'dues' => const Color(0xFF0B7A35),
    'aspiration' => const Color(0xFF5134D4),
    'letter' => const Color(0xFFC27803),
    'announcement' => const Color(0xFF0967D8),
    'membership' => const Color(0xFF0967D8),
    _ => const Color(0xFF0967D8),
  };
}

String _categoryLabel(String category) {
  return switch (category) {
    'finance' => 'Keuangan',
    'dues' => 'Keuangan',
    'aspiration' => 'Aspirasi',
    'letter' => 'Surat',
    'announcement' => 'Pengumuman',
    'membership' => 'Keanggotaan',
    'system' => 'Sistem',
    _ => 'Notifikasi',
  };
}
