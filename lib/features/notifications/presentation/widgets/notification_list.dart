import 'package:flutter/material.dart';

import '../../data/models/notification_model.dart';
import 'notification_tile.dart';

class NotificationList extends StatelessWidget {
  const NotificationList({super.key, required this.items, required this.onTap});

  final List<NotificationModel> items;
  final ValueChanged<NotificationModel> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7EDF6)),
            ),
            child: NotificationTile(notification: item, onTap: onTap),
          ),
          if (item != items.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
