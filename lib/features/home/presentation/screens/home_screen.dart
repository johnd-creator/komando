import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../../features/news/data/models/news_model.dart';
import '../../../../features/news/data/repositories/news_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/feature_access_panel.dart';
import '../widgets/home_announcement_card.dart';
import '../widgets/home_header.dart';
import '../widgets/latest_news_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NewsModel> _latestNews = const [];
  bool _isNewsLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const DashboardRequested());
    unawaited(_loadLatestNews()); // initState cannot be async
  }

  void _showLainnya(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final hasAdmin =
        authState is AuthAuthenticated && authState.user.hasAdminAccess;

    unawaited(
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
      ),
    );
  }

  void _showBendahara(BuildContext context) {
    unawaited(
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Catat transaksi'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.keuangan);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text('Kelola iuran'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.adminDues);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    context.read<DashboardBloc>().add(const DashboardRequested());
    await _loadLatestNews(refresh: true);
  }

  Future<void> _loadLatestNews({bool refresh = false}) async {
    final repository = context.read<NewsRepository>();

    if (!refresh) {
      final cached = await repository.getCachedLatestPosts();
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _latestNews = cached.take(3).toList();
        });
      }
    }

    if (mounted) {
      setState(() {
        _isNewsLoading = _latestNews.isEmpty;
      });
    }

    try {
      final posts = await repository.getLatestPosts(limit: 3);
      if (!mounted) return;
      setState(() {
        _latestNews = posts.take(3).toList();
        _isNewsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isNewsLoading = false;
      });
    }
  }

  Future<void> _openNewsItem(NewsModel item) async {
    if (item.link.isEmpty) {
      unawaited(context.push(AppRoutes.news));
      return;
    }

    final uri = Uri.parse(item.link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
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
          // Use select instead of watch to only rebuild when role changes,
          // not on every AuthBloc state emission
          final showBendahara = context.select<AuthBloc, bool>((bloc) {
            final s = bloc.state;
            return s is AuthAuthenticated &&
                s.user.normalizedRoleName != 'anggota';
          });

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: HomeHeader(
                    dashboard: dashboard,
                    greeting: _greetingForNow(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
                  sliver: SliverList.list(
                    children: [
                      FeatureAccessPanel(
                        onIuranTap: () => context.push(AppRoutes.iuran),
                        onAspirasiTap: () =>
                            context.push(AppRoutes.aspirations),
                        onSuratTap: () => context.push(AppRoutes.letters),
                        onPengumumanTap: () =>
                            context.push(AppRoutes.announcements),
                        onBendaharaTap: showBendahara
                            ? () => _showBendahara(context)
                            : null,
                        onNewsTap: () => context.push(AppRoutes.news),
                        onLainnyaTap: () => _showLainnya(context),
                      ),
                      const SizedBox(height: 16),
                      HomeAnnouncementCard(
                        isLoading: isLoading,
                        announcements: dashboard?.announcements ?? const [],
                        errorMessage: state is DashboardFailure
                            ? state.message
                            : null,
                        onRetry: _refresh,
                      ),
                      const SizedBox(height: 16),
                      LatestNewsCard(
                        isLoading: _isNewsLoading,
                        items: _latestNews,
                        onSeeAll: () => context.push(AppRoutes.news),
                        onItemTap: _openNewsItem,
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
