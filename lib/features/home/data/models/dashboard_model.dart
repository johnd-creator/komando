import '../../../../core/api/json_read.dart';

class DashboardModel {
  const DashboardModel({
    required this.memberName,
    required this.ktaStatus,
    required this.ktaNumber,
    required this.unitName,
    required this.unreadNotifications,
    required this.announcements,
  });

  final String memberName;
  final String ktaStatus;
  final String ktaNumber;
  final String unitName;
  final int unreadNotifications;
  final List<DashboardAnnouncementModel> announcements;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final data = readMap(json, 'data').isNotEmpty
        ? readMap(json, 'data')
        : json;
    final member = readMap(data, 'member').isNotEmpty
        ? readMap(data, 'member')
        : readMap(data, 'profile');
    final kta = readMap(data, 'kta').isNotEmpty
        ? readMap(data, 'kta')
        : readMap(data, 'member_card');
    final notification = readMap(data, 'notifications');
    final announcements = readList(data, 'announcements').isNotEmpty
        ? readList(data, 'announcements')
        : readList(data, 'pinned_announcements');

    return DashboardModel(
      memberName: readString(member, const [
        'name',
        'full_name',
        'member_name',
      ], fallback: 'Anggota'),
      ktaStatus: readString(kta, const [
        'status',
        'member_status',
      ], fallback: readString(member, const ['status'], fallback: 'Aktif')),
      ktaNumber: readString(kta.isNotEmpty ? kta : member, const [
        'number',
        'kta_number',
        'nomor_anggota',
        'nomor_kta',
      ], fallback: '-'),
      unitName: readString(member, const ['unit_name'], fallback: '-'),
      unreadNotifications: readInt(
        notification.isNotEmpty ? notification : data,
        const ['unread', 'unread_count', 'unread_notifications'],
      ),
      announcements: announcements
          .map(DashboardAnnouncementModel.fromJson)
          .toList(),
    );
  }
}

class DashboardAnnouncementModel {
  const DashboardAnnouncementModel({
    required this.title,
    required this.dateLabel,
  });

  final String title;
  final String dateLabel;

  factory DashboardAnnouncementModel.fromJson(Map<String, dynamic> json) {
    return DashboardAnnouncementModel(
      title: readString(json, const ['title', 'subject']),
      dateLabel: readString(json, const [
        'published_at',
        'created_at',
        'date',
      ], fallback: ''),
    );
  }
}
