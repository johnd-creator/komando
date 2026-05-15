import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../features/home/data/repositories/dashboard_repository.dart';
import '../../../features/home/presentation/bloc/dashboard_bloc.dart';
import '../../../features/home/presentation/screens/home_screen.dart';
import '../../../features/kta/data/repositories/kta_repository.dart';
import '../../../features/kta/presentation/bloc/kta_bloc.dart';
import '../../../features/kta/presentation/screens/kta_digital_screen.dart';
import '../../../features/notifications/data/repositories/notification_repository.dart';
import '../../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../../features/notifications/presentation/screens/notification_screen.dart';
import '../../../features/profile/data/repositories/profile_repository.dart';
import '../../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../../features/profile/presentation/screens/profile_screen.dart';
import '../notifiers/bottom_nav_notifier.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    KtaDigitalScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final notifier = BottomNavScope.of(context);
    final selectedIndex = notifier.index;

    return MultiBlocProvider(
      providers: [
        // These 4 blocs are scoped to MainShell — only created when shell mounts,
        // reducing cold start time vs placing them at the root provider.
        BlocProvider(
          create: (_) => DashboardBloc(DashboardRepository(apiClient)),
        ),
        BlocProvider(create: (_) => KtaBloc(KtaRepository(apiClient))),
        BlocProvider(
          create: (_) => NotificationBloc(NotificationRepository(apiClient)),
        ),
        BlocProvider(create: (_) => ProfileBloc(ProfileRepository(apiClient))),
      ],
      child: Scaffold(
        body: IndexedStack(index: selectedIndex, children: _screens),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: const Color(0xFFE7F0FF),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            notifier.goToTab(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.badge_outlined),
              selectedIcon: Icon(Icons.badge_rounded),
              label: 'KTA',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: 'Notifikasi',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
