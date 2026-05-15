import 'package:flutter/material.dart';

import '../../data/models/notification_model.dart';
import 'notification_helpers.dart';
import 'notification_visual.dart';
import 'unread_dot.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final ValueChanged<NotificationModel> onTap;

  @override
  Widget build(BuildContext context) {
    final meta = NotificationVisual.from(notification);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(notification),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                child: UnreadDot(isRead: notification.isRead),
              ),
              const SizedBox(width: 10),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: meta.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(meta.icon, color: meta.foreground, size: 31),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _titleFor(notification),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: const Color(0xFF0B1B37),
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF51617A),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF50617B),
                        height: 1.34,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.blueGrey.shade300,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(NotificationModel notification) {
    final message = notification.message.trim();
    if (message.isEmpty) return categoryLabel(notification.category);

    final separators = ['\n', '.', ':', '-'];
    var end = message.length;
    for (final separator in separators) {
      final index = message.indexOf(separator);
      if (index > 8 && index < end) end = index;
    }

    final title = message.substring(0, end).trim();
    if (title.length > 46) return categoryLabel(notification.category);
    return title;
  }

  String _formatTime(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 1) return 'Kemarin';
      if (diff.inDays > 1) return '${date.day}/${date.month}/${date.year}';
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return isoDate;
    }
  }
}
