import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../shared/presentation/widgets/feature_grid_item.dart';
import '../../../../shared/presentation/widgets/section_title.dart';
import '../../../../shared/presentation/notifiers/bottom_nav_notifier.dart';
import '../../data/models/dashboard_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const DashboardRequested());
  }

  void _showLainnya(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final hasAdmin =
        authState is AuthAuthenticated && authState.user.hasAdminAccess;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Feedback'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.feedback);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Pengaturan'),
              enabled: false,
            ),
            if (hasAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin Panel'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.admin);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openKeuangan(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final canAccessFinance =
        authState is AuthAuthenticated && authState.user.canAccessFinance;

    if (canAccessFinance) {
      context.push(AppRoutes.keuangan);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Keuangan organisasi hanya tersedia untuk pengurus atau bendahara.',
          ),
          action: SnackBarAction(
            label: 'Iuran Saya',
            onPressed: () => context.push(AppRoutes.iuran),
          ),
        ),
      );
  }

  Future<void> _refresh() async {
    context.read<DashboardBloc>().add(const DashboardRequested());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final dashboard = state is DashboardLoaded ? state.dashboard : null;
          final isLoading =
              state is DashboardLoading || state is DashboardInitial;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                    color: colorScheme.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat datang,',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colorScheme.onPrimary
                                              .withValues(alpha: 0.82),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dashboard?.memberName ?? 'Anggota',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Badge(
                              label: Text(
                                '${dashboard?.unreadNotifications ?? 0}',
                              ),
                              isLabelVisible:
                                  (dashboard?.unreadNotifications ?? 0) > 0,
                              child: IconButton.filledTonal(
                                onPressed: () =>
                                    BottomNavScope.of(context).goToTab(2),
                                tooltip: 'Notifikasi',
                                icon: const Icon(Icons.notifications_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Card(
                          color: colorScheme.onPrimary,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => context.push('/kta'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('KTA'),
                                        const SizedBox(height: 2),
                                        Text(
                                          dashboard?.ktaNumber ??
                                              'Memuat nomor KTA',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dashboard?.unitName ??
                                              'Memuat unit organisasi',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList.list(
                    children: [
                      const SectionTitle(title: 'Akses fitur'),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: GridView.count(
                            crossAxisCount: 4,
                            childAspectRatio: 0.82,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              FeatureGridItem(
                                icon: Icons.badge_outlined,
                                label: 'KTA',
                                onTap: () => context.push('/kta'),
                              ),
                              FeatureGridItem(
                                icon: Icons.receipt_long_outlined,
                                label: 'Iuran',
                                onTap: () => context.push(AppRoutes.iuran),
                              ),
                              FeatureGridItem(
                                icon: Icons.forum_outlined,
                                label: 'Aspirasi',
                                onTap: () =>
                                    context.push(AppRoutes.aspirations),
                              ),
                              FeatureGridItem(
                                icon: Icons.mail_outline_rounded,
                                label: 'Surat',
                                onTap: () => context.push(AppRoutes.letters),
                              ),
                              FeatureGridItem(
                                icon: Icons.campaign_outlined,
                                label: 'Pengumuman',
                                onTap: () =>
                                    context.push(AppRoutes.announcements),
                              ),
                              FeatureGridItem(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Keuangan',
                                onTap: () => _openKeuangan(context),
                              ),
                              FeatureGridItem(
                                icon: Icons.article_outlined,
                                label: 'News',
                                onTap: () => context.push(AppRoutes.news),
                              ),
                              FeatureGridItem(
                                icon: Icons.apps_rounded,
                                label: 'Lainnya',
                                onTap: () => _showLainnya(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SectionTitle(
                        title: 'Pengumuman terbaru',
                        actionLabel: 'Lihat semua',
                      ),
                      const SizedBox(height: 8),
                      _AnnouncementCard(
                        isLoading: isLoading,
                        announcements: dashboard?.announcements ?? const [],
                        errorMessage: state is DashboardFailure
                            ? state.message
                            : null,
                        onRetry: _refresh,
                      ),
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
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.isLoading,
    required this.announcements,
    required this.onRetry,
    this.errorMessage,
  });

  final bool isLoading;
  final List<DashboardAnnouncementModel> announcements;
  final VoidCallback onRetry;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: ListTile(
          leading: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Memuat pengumuman'),
        ),
      );
    }

    if (errorMessage != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline_rounded),
          title: Text(errorMessage!),
          trailing: IconButton(
            tooltip: 'Coba lagi',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      );
    }

    if (announcements.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.campaign_outlined),
          title: Text('Belum ada pengumuman terbaru'),
          subtitle: Text('Tarik ke bawah untuk memuat ulang.'),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (final announcement in announcements.take(3))
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: Text(announcement.title),
              subtitle: announcement.dateLabel.isEmpty
                  ? null
                  : Text(announcement.dateLabel),
              onTap: () => context.push(AppRoutes.announcements),
            ),
        ],
      ),
    );
  }
}
