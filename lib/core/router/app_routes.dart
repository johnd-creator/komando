class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const announcements = '/announcements';
  static const aspirations = '/aspirations';
  static const aspirationCreate = '/aspirations/create';
  static const letters = '/letters';
  static const letterCreate = '/letters/create';
  static const feedback = '/feedback';
  static const news = '/news';

  static String announcementDetail(int id) => '/announcements/$id';
  static String aspirationDetail(int id) => '/aspirations/$id';
  static String letterDetail(int id) => '/letters/$id';
}
