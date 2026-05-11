import 'package:flutter/material.dart';

class DuesMassPayDialog extends StatefulWidget {
  final int count;
  final double defaultAmount;

  const DuesMassPayDialog({
    super.key,
    required this.count,
    required this.defaultAmount,
  });

  @override
  State<DuesMassPayDialog> createState() => _DuesMassPayDialogState();
}

class _DuesMassPayDialogState extends State<DuesMassPayDialog> {
  late TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.defaultAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pembayaran Massal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan mencatat pembayaran lunas untuk ${widget.count} anggota.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal per Anggota',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'amount':
                  double.tryParse(_amountController.text) ??
                  widget.defaultAmount,
              'notes': _notesController.text,
            });
          },
          child: const Text('Konfirmasi'),
        ),
      ],
    );
  }
}
