import 'package:flutter/material.dart';

import '../../data/models/notification_model.dart';
import 'notification_tile.dart';

class NotificationGroupCard extends StatelessWidget {
  const NotificationGroupCard({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<NotificationModel> items;
  final ValueChanged<NotificationModel> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A4667).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            NotificationTile(notification: items[index], onTap: onTap),
            if (index != items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 86, right: 14),
                child: Divider(height: 1, color: Color(0xFFE0E7F0)),
              ),
          ],
        ],
      ),
    );
  }
}
