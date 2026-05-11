import 'package:flutter/material.dart';

class DuesFilterBar extends StatelessWidget {
  final Map<String, String> currentFilters;
  final Function(Map<String, String>) onFilterChanged;

  const DuesFilterBar({
    super.key,
    required this.currentFilters,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari anggota / KTA...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (value) {
                onFilterChanged({'member_id': value}); // Simplified for search
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter dialog or bottom sheet for period and unit
            },
          ),
        ],
      ),
    );
  }
}
