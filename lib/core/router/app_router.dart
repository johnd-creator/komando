import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/announcements/data/repositories/announcement_repository.dart';
import '../../features/announcements/presentation/bloc/announcement_bloc.dart';
import '../../features/announcements/presentation/screens/announcement_detail_screen.dart';
import '../../features/announcements/presentation/screens/announcement_list_screen.dart';
import '../../features/aspirations/data/repositories/aspiration_repository.dart';
import '../../features/aspirations/presentation/bloc/aspiration_bloc.dart';
import '../../features/aspirations/presentation/screens/aspiration_create_screen.dart';
import '../../features/aspirations/presentation/screens/aspiration_detail_screen.dart';
import '../../features/aspirations/presentation/screens/aspiration_list_screen.dart';
import '../../features/kta/presentation/screens/kta_digital_screen.dart';
import '../../features/letters/data/repositories/letter_repository.dart';
import '../../features/letters/presentation/bloc/letter_bloc.dart';
import '../../features/letters/presentation/screens/letter_create_screen.dart';
import '../../features/letters/presentation/screens/letter_detail_screen.dart';
import '../../features/letters/presentation/screens/letter_list_screen.dart';
import '../../features/feedback/data/repositories/feedback_repository.dart';
import '../../features/feedback/presentation/bloc/feedback_bloc.dart';
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/finance/data/repositories/finance_repository.dart';
import '../../features/finance/presentation/bloc/finance_bloc.dart';
import '../../features/finance/presentation/bloc/finance_event.dart';
import '../../features/finance/presentation/screens/keuangan_screen.dart';
import '../../features/finance/presentation/screens/ledger_form_screen.dart';
import '../../features/finance/presentation/screens/ledger_detail_screen.dart';
import '../../features/admin/data/repositories/admin_repository.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/member_list_screen.dart';
import '../../features/admin/presentation/screens/member_detail_screen.dart';
import '../../features/admin/presentation/screens/reports_screen.dart';
import '../../features/news/data/repositories/news_repository.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';
import '../../features/news/presentation/screens/news_list_screen.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dues/repository/dues_repository.dart';
import '../../features/dues/bloc/dues_bloc.dart';
import '../../features/dues/bloc/dues_admin_bloc.dart';
import '../../features/dues/screens/my_dues_screen.dart';
import '../../features/dues/screens/dues_admin_list_screen.dart';
import '../../shared/presentation/screens/main_shell.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter({
    required AuthBloc authBloc,
    required AnnouncementRepository announcementRepository,
    required AspirationRepository aspirationRepository,
    required LetterRepository letterRepository,
    required FeedbackRepository feedbackRepository,
    required NewsRepository newsRepository,
    required FinanceRepository financeRepository,
    required AdminRepository adminRepository,
    required DuesRepository duesRepository,
  }) : _authBloc = authBloc,
       _announcementRepository = announcementRepository,
       _aspirationRepository = aspirationRepository,
       _letterRepository = letterRepository,
       _feedbackRepository = feedbackRepository,
       _newsRepository = newsRepository,
       _financeRepository = financeRepository,
       _adminRepository = adminRepository,
       _duesRepository = duesRepository;

  final AuthBloc _authBloc;
  final AnnouncementRepository _announcementRepository;
  final AspirationRepository _aspirationRepository;
  final LetterRepository _letterRepository;
  final FeedbackRepository _feedbackRepository;
  final NewsRepository _newsRepository;
  final FinanceRepository _financeRepository;
  final AdminRepository _adminRepository;
  final DuesRepository _duesRepository;

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
        path: '/kta',
        builder: (context, state) => const KtaDigitalScreen(),
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
      GoRoute(
        path: AppRoutes.aspirations,
        builder: (context, state) => BlocProvider(
          create: (_) => AspirationBloc(_aspirationRepository),
          child: const AspirationListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.aspirationCreate,
        builder: (context, state) => BlocProvider(
          create: (_) => AspirationBloc(_aspirationRepository),
          child: const AspirationCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/aspirations/:id',
        builder: (context, state) => BlocProvider(
          create: (_) => AspirationBloc(_aspirationRepository),
          child: AspirationDetailScreen(
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.letters,
        builder: (context, state) => BlocProvider(
          create: (_) => LetterBloc(_letterRepository),
          child: const LetterListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.letterCreate,
        builder: (context, state) => BlocProvider(
          create: (_) => LetterBloc(_letterRepository),
          child: const LetterCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/letters/:id',
        builder: (context, state) => BlocProvider(
          create: (_) => LetterBloc(_letterRepository),
          child: LetterDetailScreen(
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.feedback,
        builder: (context, state) => BlocProvider(
          create: (_) => FeedbackBloc(_feedbackRepository),
          child: const FeedbackScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.news,
        builder: (context, state) => BlocProvider(
          create: (_) => NewsBloc(_newsRepository),
          child: const NewsListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.iuran,
        builder: (context, state) => BlocProvider(
          create: (_) => DuesBloc(repository: _duesRepository),
          child: const MyDuesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.keuangan,
        builder: (context, state) => BlocProvider(
          create: (_) => FinanceBloc(_financeRepository),
          child: const KeuanganScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.financeLedgerCreate,
        builder: (context, state) => BlocProvider(
          create: (_) => FinanceBloc(_financeRepository),
          child: const LedgerFormScreen(),
        ),
      ),
      GoRoute(
        path: '/finance/ledgers/:id/edit',
        builder: (context, state) => BlocProvider(
          create: (_) => FinanceBloc(_financeRepository),
          child: LedgerFormScreen(
            editId: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: '/finance/ledgers/:id',
        builder: (context, state) => BlocProvider(
          create: (_) => FinanceBloc(_financeRepository)
            ..add(
              FinanceLedgerDetailFetched(
                int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
          child: LedgerDetailScreen(
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => BlocProvider(
          create: (_) => AdminBloc(_adminRepository),
          child: const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminMembers,
        builder: (context, state) => BlocProvider(
          create: (_) => AdminBloc(_adminRepository),
          child: const MemberListScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/members/:id',
        builder: (context, state) => BlocProvider(
          create: (_) => AdminBloc(_adminRepository),
          child: MemberDetailScreen(
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) => BlocProvider(
          create: (_) => AdminBloc(_adminRepository),
          child: const ReportsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminDues,
        builder: (context, state) => BlocProvider(
          create: (_) => DuesAdminBloc(repository: _duesRepository),
          child: const DuesAdminListScreen(),
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
