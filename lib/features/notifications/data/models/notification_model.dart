import '../../../../core/api/json_read.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final String createdAt;
  final bool isRead;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: readString(json, const ['id', 'uuid']),
      title: readString(json, const ['title', 'subject']),
      body: readString(json, const [
        'body',
        'message',
        'content',
      ], fallback: ''),
      createdAt: readString(json, const ['created_at', 'date'], fallback: ''),
      isRead:
          json['read_at'] != null ||
          json['is_read'] == true ||
          json['read'] == true,
    );
  }
}

class NotificationPageModel {
  const NotificationPageModel({required this.items, required this.unreadCount});

  final List<NotificationModel> items;
  final int unreadCount;

  factory NotificationPageModel.fromJson(Map<String, dynamic> json) {
    final data = readMap(json, 'data').isNotEmpty
        ? readMap(json, 'data')
        : json;
    final paginatedItems = readList(data, 'data');
    final items = paginatedItems.isNotEmpty
        ? paginatedItems
        : readList(data, 'notifications').isNotEmpty
        ? readList(data, 'notifications')
        : readList(json, 'data');
    final notifications = items.map(NotificationModel.fromJson).toList();

    return NotificationPageModel(
      items: notifications,
      unreadCount: readInt(data, const [
        'unread_count',
      ], fallback: notifications.where((item) => !item.isRead).length),
    );
  }
}
