import 'package:flutter/material.dart';

import 'notification_filter_panel.dart';
import 'notification_header.dart';

class NotificationTopSection extends StatelessWidget {
  const NotificationTopSection({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const NotificationHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 258, 14, 0),
          child: NotificationFilterPanel(
            selectedCategory: selectedCategory,
            onSelected: onSelected,
          ),
        ),
      ],
    );
  }
}
