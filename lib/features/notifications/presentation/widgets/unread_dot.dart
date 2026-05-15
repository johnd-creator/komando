import 'package:flutter/material.dart';

class UnreadDot extends StatelessWidget {
  const UnreadDot({super.key, required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isRead ? 0 : 1,
      duration: const Duration(milliseconds: 160),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFF0967D8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
