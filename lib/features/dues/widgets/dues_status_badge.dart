import 'package:flutter/material.dart';

class DuesStatusBadge extends StatelessWidget {
  final String status;

  const DuesStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'paid':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'LUNAS';
        break;
      case 'waived':
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        label = 'BEBAS';
        break;
      case 'unpaid':
      default:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'BELUM LUNAS';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
