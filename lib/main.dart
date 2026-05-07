import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/api/api_client.dart';
import 'core/router/app_router.dart';
import 'core/security/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/announcements/data/repositories/announcement_repository.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/restore_session_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/data/repositories/dashboard_repository.dart';
import 'features/home/presentation/bloc/dashboard_bloc.dart';
import 'features/kta/data/repositories/kta_repository.dart';
import 'features/kta/presentation/bloc/kta_bloc.dart';
import 'features/notifications/data/repositories/notification_repository.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final announcementRepository = AnnouncementRepository(apiClient);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(apiClient),
    tokenStorage: tokenStorage,
  );
  final authBloc = AuthBloc(
    loginUseCase: LoginUseCase(authRepository),
    logoutUseCase: LogoutUseCase(authRepository),
    restoreSessionUseCase: RestoreSessionUseCase(authRepository),
  );
  final appRouter = AppRouter(
    authBloc: authBloc,
    announcementRepository: announcementRepository,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider(
          create: (_) => DashboardBloc(DashboardRepository(apiClient)),
        ),
        BlocProvider(create: (_) => KtaBloc(KtaRepository(apiClient))),
        BlocProvider(
          create: (_) => NotificationBloc(NotificationRepository(apiClient)),
        ),
        BlocProvider(create: (_) => ProfileBloc(ProfileRepository(apiClient))),
      ],
      child: KomandoApp(appRouter: appRouter),
    ),
  );
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
