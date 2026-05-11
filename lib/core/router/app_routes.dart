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
  static const iuran = '/iuran';
  static const keuangan = '/keuangan';
  static const financeLedgerCreate = '/finance/ledgers/create';
  static const admin = '/admin';
  static const adminMembers = '/admin/members';
  static const adminReports = '/admin/reports';
  static const adminDues = '/admin/dues';

  static String announcementDetail(int id) => '/announcements/$id';
  static String aspirationDetail(int id) => '/aspirations/$id';
  static String letterDetail(int id) => '/letters/$id';
  static String financeLedgerDetail(int id) => '/finance/ledgers/$id';
  static String financeLedgerEdit(int id) => '/finance/ledgers/$id/edit';
  static String adminMemberDetail(int id) => '/admin/members/$id';
}
