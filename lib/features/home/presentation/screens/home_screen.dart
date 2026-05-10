import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
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
            const ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Pengaturan'),
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
    context.push(AppRoutes.keuangan);
  }

  Future<void> _refresh() async {
    context.read<DashboardBloc>().add(const DashboardRequested());
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;

    if (hour >= 4 && hour < 11) {
      return 'Selamat pagi,';
    }
    if (hour >= 11 && hour < 15) {
      return 'Selamat siang,';
    }
    if (hour >= 15 && hour < 18) {
      return 'Selamat sore,';
    }
    return 'Selamat malam,';
  }

  @override
  Widget build(BuildContext context) {
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
                  child: _HomeHeader(
                    dashboard: dashboard,
                    greeting: _greetingForNow(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                  sliver: SliverList.list(
                    children: [
                      _FeatureAccessPanel(
                        onKtaTap: () => context.push('/kta'),
                        onIuranTap: () => context.push(AppRoutes.iuran),
                        onAspirasiTap: () =>
                            context.push(AppRoutes.aspirations),
                        onSuratTap: () => context.push(AppRoutes.letters),
                        onPengumumanTap: () =>
                            context.push(AppRoutes.announcements),
                        onKeuanganTap: () => _openKeuangan(context),
                        onNewsTap: () => context.push(AppRoutes.news),
                        onLainnyaTap: () => _showLainnya(context),
                      ),
                      const SizedBox(height: 16),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.dashboard, required this.greeting});

  final DashboardModel? dashboard;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final notificationCount = dashboard?.unreadNotifications ?? 0;

    return SizedBox(
      height: 392,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/bg-main.png',
                  fit: BoxFit.fill,
                  alignment: Alignment.topCenter,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0069D7).withValues(alpha: 0.78),
                        const Color(0xFF075EC4).withValues(alpha: 0.70),
                        const Color(0xFF064FA8).withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 74,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F9FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Badge(
                      backgroundColor: const Color(0xFFFFC928),
                      label: Text('$notificationCount'),
                      isLabelVisible: notificationCount > 0,
                      child: IconButton(
                        onPressed: () => BottomNavScope.of(context).goToTab(2),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              width: 78,
                              height: 78,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '1Komando',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Serikat Pekerja PLN Indonesia Power Services',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dashboard?.memberName ?? 'Anggota',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: _KtaStatusCard(dashboard: dashboard),
          ),
        ],
      ),
    );
  }
}

class _KtaStatusCard extends StatelessWidget {
  const _KtaStatusCard({required this.dashboard});

  final DashboardModel? dashboard;

  @override
  Widget build(BuildContext context) {
    final status = dashboard?.ktaStatus ?? 'Memuat status';
    final ktaNumber = dashboard?.ktaNumber ?? 'Memuat nomor KTA';
    final unitName = dashboard?.unitName ?? 'Memuat unit organisasi';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/kta'),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6EABF4), Color(0xFF327BD9)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B4E9D).withValues(alpha: 0.22),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status KTA',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: status),
                          const TextSpan(
                            text: '  •  ',
                            style: TextStyle(color: Color(0xFFFFC928)),
                          ),
                          TextSpan(text: ktaNumber),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      unitName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureAccessPanel extends StatelessWidget {
  const _FeatureAccessPanel({
    required this.onKtaTap,
    required this.onIuranTap,
    required this.onAspirasiTap,
    required this.onSuratTap,
    required this.onPengumumanTap,
    required this.onKeuanganTap,
    required this.onNewsTap,
    required this.onLainnyaTap,
  });

  final VoidCallback onKtaTap;
  final VoidCallback onIuranTap;
  final VoidCallback onAspirasiTap;
  final VoidCallback onSuratTap;
  final VoidCallback onPengumumanTap;
  final VoidCallback onKeuanganTap;
  final VoidCallback onNewsTap;
  final VoidCallback onLainnyaTap;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akses fitur',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            childAspectRatio: 0.9,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _FeatureTile(
                icon: Icons.badge_outlined,
                label: 'KTA Digital',
                foreground: const Color(0xFF1168CF),
                background: const Color(0xFFEAF4FF),
                onTap: onKtaTap,
              ),
              _FeatureTile(
                icon: Icons.payments_outlined,
                label: 'Iuran',
                foreground: const Color(0xFF04784A),
                background: const Color(0xFFEAF7EF),
                onTap: onIuranTap,
              ),
              _FeatureTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Aspirasi',
                foreground: const Color(0xFF5144D9),
                background: const Color(0xFFF0EEFF),
                onTap: onAspirasiTap,
              ),
              _FeatureTile(
                icon: Icons.mail_outline_rounded,
                label: 'Surat',
                foreground: const Color(0xFFB66A00),
                background: const Color(0xFFFFF4DF),
                onTap: onSuratTap,
              ),
              _FeatureTile(
                icon: Icons.notifications_active_outlined,
                label: 'Pengumuman',
                foreground: const Color(0xFFC23A2A),
                background: const Color(0xFFFFECE9),
                onTap: onPengumumanTap,
              ),
              _FeatureTile(
                icon: Icons.request_quote_outlined,
                label: 'Keuangan',
                foreground: const Color(0xFF2E7D32),
                background: const Color(0xFFEDF7E8),
                onTap: onKeuanganTap,
              ),
              _FeatureTile(
                icon: Icons.newspaper_rounded,
                label: 'News',
                foreground: const Color(0xFFC03F86),
                background: const Color(0xFFFFEEF7),
                onTap: onNewsTap,
              ),
              _FeatureTile(
                icon: Icons.more_horiz_rounded,
                label: 'Lainnya',
                foreground: const Color(0xFF4B5563),
                background: const Color(0xFFF4F5F7),
                onTap: onLainnyaTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: foreground.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: foreground, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              height: 1.05,
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14345F).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
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
    return _SoftPanel(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alert terbaru',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.push(AppRoutes.announcements),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Memuat alert'),
            )
          else if (errorMessage != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.error_outline_rounded),
              title: Text(errorMessage!),
              trailing: IconButton(
                tooltip: 'Coba lagi',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
            )
          else if (announcements.isEmpty)
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.campaign_outlined),
              title: Text('Belum ada alert terbaru'),
              subtitle: Text('Tarik ke bawah untuk memuat ulang.'),
            )
          else
            for (final entry in announcements.take(3).indexed) ...[
              _AnnouncementTile(
                announcement: entry.$2,
                icon: _announcementIconFor(entry.$1),
                showDivider: entry.$1 < announcements.take(3).length - 1,
              ),
            ],
        ],
      ),
    );
  }

  static IconData _announcementIconFor(int index) {
    return switch (index) {
      0 => Icons.calendar_month_outlined,
      1 => Icons.account_balance_wallet_outlined,
      _ => Icons.description_outlined,
    };
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({
    required this.announcement,
    required this.icon,
    required this.showDivider,
  });

  final DashboardAnnouncementModel announcement;
  final IconData icon;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => context.push(AppRoutes.announcements),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF0968D7),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: const Color(0xFF1168CF), size: 27),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      if (announcement.dateLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          announcement.dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF667085)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8A98AA),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 74, color: Color(0xFFE5EAF1)),
      ],
    );
  }
}
