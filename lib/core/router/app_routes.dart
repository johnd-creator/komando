class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const announcements = '/announcements';

  static String announcementDetail(int id) => '/announcements/$id';
}
