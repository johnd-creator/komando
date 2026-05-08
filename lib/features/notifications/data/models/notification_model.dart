import '../../../../core/api/json_read.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.category,
    required this.link,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String type;
  final String message;
  final String category;
  final String? link;
  final String createdAt;
  final bool isRead;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: readString(json, const ['id', 'uuid']),
      type: readString(json, const ['type', 'category'], fallback: 'general'),
      message: readString(json, const ['message', 'title', 'body']),
      category: readString(json, const ['category'], fallback: 'general'),
      link: json['link'] as String?,
      createdAt: readString(json, const ['created_at', 'date'], fallback: ''),
      isRead: json['read_at'] != null,
    );
  }
}

class NotificationPageModel {
  const NotificationPageModel({required this.items, required this.unreadCount});

  final List<NotificationModel> items;
  final int unreadCount;

  factory NotificationPageModel.fromJson(Map<String, dynamic> json) {
    final items = readList(json, 'items');
    final meta = readMap(json, 'meta');
    final notifications = items.map(NotificationModel.fromJson).toList();

    return NotificationPageModel(
      items: notifications,
      unreadCount: readInt(
        meta.isNotEmpty ? meta : json,
        const ['unread_count'],
        fallback: notifications.where((item) => !item.isRead).length,
      ),
    );
  }
}
