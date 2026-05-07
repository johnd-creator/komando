import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/feature_grid_item.dart';
import '../../../../shared/presentation/widgets/section_title.dart';
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
                                onPressed: () {},
                                tooltip: 'Notifikasi',
                                icon: const Icon(Icons.notifications_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Card(
                          color: colorScheme.onPrimary,
                          child: ListTile(
                            leading: Icon(
                              Icons.badge_outlined,
                              color: colorScheme.primary,
                            ),
                            title: const Text('Status KTA'),
                            subtitle: Text(
                              '${dashboard?.ktaStatus ?? 'Memuat'} · ${dashboard?.ktaNumber ?? 'Nomor KTA'}',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {},
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
                              const FeatureGridItem(
                                icon: Icons.badge_outlined,
                                label: 'KTA',
                              ),
                              const FeatureGridItem(
                                icon: Icons.receipt_long_outlined,
                                label: 'Iuran',
                              ),
                              const FeatureGridItem(
                                icon: Icons.forum_outlined,
                                label: 'Aspirasi',
                              ),
                              const FeatureGridItem(
                                icon: Icons.mail_outline_rounded,
                                label: 'Surat',
                              ),
                              FeatureGridItem(
                                icon: Icons.campaign_outlined,
                                label: 'Pengumuman',
                                onTap: () =>
                                    context.push(AppRoutes.announcements),
                              ),
                              const FeatureGridItem(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Keuangan',
                              ),
                              const FeatureGridItem(
                                icon: Icons.article_outlined,
                                label: 'News',
                              ),
                              const FeatureGridItem(
                                icon: Icons.apps_rounded,
                                label: 'Lainnya',
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
