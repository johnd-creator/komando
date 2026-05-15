import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/presentation/notifiers/bottom_nav_notifier.dart';
import '../../data/models/dashboard_model.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.dashboard,
    required this.greeting,
  });

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
                  'assets/bg-asset.png',
                  fit: BoxFit.contain,
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
                color: AppColors.surfaceAlt,
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
        onTap: () => BottomNavScope.of(context).goToTab(1),
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
