import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/api/api_client.dart';
import 'core/observability/crash_reporter.dart';
import 'firebase_options.dart';
import 'core/security/biometric_auth_service.dart';
import 'core/router/app_router.dart';
import 'core/security/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/announcements/data/repositories/announcement_repository.dart';
import 'features/aspirations/data/repositories/aspiration_repository.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/biometric_login_usecase.dart';
import 'features/auth/domain/usecases/get_login_preferences_usecase.dart';
import 'features/auth/domain/usecases/google_login_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/restore_session_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/letters/data/repositories/letter_repository.dart';
import 'features/feedback/data/repositories/feedback_repository.dart';
import 'features/news/data/repositories/news_repository.dart';
import 'features/news/data/wordpress_client.dart';
import 'features/finance/data/repositories/finance_repository.dart';
import 'features/admin/data/repositories/admin_repository.dart';
import 'features/dues/repository/dues_repository.dart';
import 'shared/presentation/notifiers/bottom_nav_notifier.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with platform-specific options from google-services.json
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await CrashReporter.init();

    // Catch Flutter framework errors (widget build errors, rendering issues)
    FlutterError.onError = CrashReporter.recordFlutterError;

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);
    final announcementRepository = AnnouncementRepository(apiClient);
    final aspirationRepository = AspirationRepository(apiClient);
    final letterRepository = LetterRepository(apiClient);
    final feedbackRepository = FeedbackRepository(apiClient);
    final newsRepository = NewsRepository(WordpressClient());
    final financeRepository = FinanceRepository(apiClient);
    final adminRepository = AdminRepository(apiClient);
    final duesRepository = DuesRepository(apiClient.dio);
    final bottomNavNotifier = BottomNavNotifier();
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(apiClient),
      tokenStorage: tokenStorage,
      biometricAuthService: BiometricAuthService(),
    );
    final authBloc = AuthBloc(
      loginUseCase: LoginUseCase(authRepository),
      logoutUseCase: LogoutUseCase(authRepository),
      restoreSessionUseCase: RestoreSessionUseCase(authRepository),
      getLoginPreferencesUseCase: GetLoginPreferencesUseCase(authRepository),
      biometricLoginUseCase: BiometricLoginUseCase(authRepository),
      googleLoginUseCase: GoogleLoginUseCase(authRepository),
    );
    final appRouter = AppRouter(
      authBloc: authBloc,
      announcementRepository: announcementRepository,
      aspirationRepository: aspirationRepository,
      letterRepository: letterRepository,
      feedbackRepository: feedbackRepository,
      newsRepository: newsRepository,
      financeRepository: financeRepository,
      adminRepository: adminRepository,
      duesRepository: duesRepository,
    );

    runApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: adminRepository),
          RepositoryProvider.value(value: newsRepository),
          // Shell repositories — passed down so MainShell can create blocs lazily
          RepositoryProvider.value(value: apiClient),
        ],
        child: MultiBlocProvider(
          providers: [
            // Only AuthBloc lives at root — it's needed before MainShell mounts
            BlocProvider.value(value: authBloc),
          ],
          child: BottomNavScope(
            notifier: bottomNavNotifier,
            child: KomandoApp(appRouter: appRouter),
          ),
        ),
      ),
    );
  }, CrashReporter.recordError);
}

class KomandoApp extends StatelessWidget {
  const KomandoApp({required this.appRouter, super.key});

  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '1Komando',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter.router,
    );
  }
}
