import 'package:flutter/material.dart';

import '../../data/models/finance_model.dart';

class FinanceFilterBar extends StatelessWidget {
  const FinanceFilterBar({
    super.key,
    required this.units,
    required this.selectedUnitId,
    required this.selectedType,
    required this.selectedStatus,
    required this.onUnitChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
  });

  final List<FinanceUnitModel> units;
  final int? selectedUnitId;
  final String? selectedType;
  final String? selectedStatus;
  final ValueChanged<int?> onUnitChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 20,
                color: Color(0xFF126ED3),
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Transaksi',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF071A3A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (units.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: selectedUnitId,
              decoration: InputDecoration(
                labelText: 'Unit',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF6F9FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDDE8F5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDDE8F5)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Unit')),
                ...units.map(
                  (u) => DropdownMenuItem(
                    value: u.id,
                    child: Text(u.isPusat ? '${u.name} (Pusat)' : u.name),
                  ),
                ),
              ],
              onChanged: onUnitChanged,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FinanceFilterChip(
                label: 'Semua',
                selected: selectedType == null,
                onTap: () => onTypeChanged(null),
              ),
              _FinanceFilterChip(
                label: 'Pemasukan',
                selected: selectedType == 'income',
                onTap: () => onTypeChanged('income'),
              ),
              _FinanceFilterChip(
                label: 'Pengeluaran',
                selected: selectedType == 'expense',
                onTap: () => onTypeChanged('expense'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FinanceFilterChip(
                label: 'Semua Status',
                selected: selectedStatus == null,
                onTap: () => onStatusChanged(null),
              ),
              _FinanceFilterChip(
                label: 'Disetujui',
                selected: selectedStatus == 'approved',
                onTap: () => onStatusChanged('approved'),
              ),
              _FinanceFilterChip(
                label: 'Menunggu',
                selected: selectedStatus == 'submitted',
                onTap: () => onStatusChanged('submitted'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceFilterChip extends StatelessWidget {
  const _FinanceFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: const Color(0xFF126ED3),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF126ED3) : const Color(0xFFDDE8F5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? Colors.white : const Color(0xFF51627A),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
