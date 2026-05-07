import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/announcements/data/repositories/announcement_repository.dart';
import '../../features/announcements/presentation/bloc/announcement_bloc.dart';
import '../../features/announcements/presentation/screens/announcement_detail_screen.dart';
import '../../features/announcements/presentation/screens/announcement_list_screen.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../shared/presentation/screens/main_shell.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter({
    required AuthBloc authBloc,
    required AnnouncementRepository announcementRepository,
  }) : _authBloc = authBloc,
       _announcementRepository = announcementRepository;

  final AuthBloc _authBloc;
  final AnnouncementRepository _announcementRepository;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _GoRouterRefreshStream(_authBloc.stream),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: AppRoutes.announcements,
        builder: (context, state) => BlocProvider(
          create: (_) => AnnouncementBloc(_announcementRepository),
          child: const AnnouncementListScreen(),
        ),
      ),
      GoRoute(
        path: '/announcements/:id',
        builder: (context, state) => BlocProvider(
          create: (_) => AnnouncementBloc(_announcementRepository),
          child: AnnouncementDetailScreen(
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
    ],
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final location = state.matchedLocation;

      if (authState is AuthInitial) {
        context.read<AuthBloc>().add(const AuthSessionRestoreRequested());
        return AppRoutes.splash;
      }

      if (authState is AuthLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (authState is AuthAuthenticated) {
        return location == AppRoutes.login || location == AppRoutes.splash
            ? AppRoutes.home
            : null;
      }

      return location == AppRoutes.login ? null : AppRoutes.login;
    },
  );
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
