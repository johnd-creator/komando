import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../data/models/finance_model.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';

class LedgerFormScreen extends StatefulWidget {
  const LedgerFormScreen({super.key, this.editId});

  final int? editId;

  @override
  State<LedgerFormScreen> createState() => _LedgerFormScreenState();
}

class _LedgerFormScreenState extends State<LedgerFormScreen> {
  static const _maxAttachmentSizeBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _dateCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _categoryId;
  int? _unitId;
  String _type = 'income';
  bool _prefilled = false;
  PlatformFile? _attachment;

  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(
      FinanceLedgerFormRequested(editId: widget.editId),
    );
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _prefill(FinanceLedgerModel ledger) {
    setState(() {
      _dateCtrl.text = ledger.date;
      _amountCtrl.text = ledger.amount.toStringAsFixed(0);
      _descCtrl.text = ledger.description;
      _type = ledger.type;
      _categoryId = ledger.categoryId;
      _unitId = ledger.unitId;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = DateTime.tryParse(_dateCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    _dateCtrl.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: false,
    );
    final file = result?.files.single;
    if (file == null) return;
    if (file.path == null || file.path!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File tidak dapat dibaca.')));
      return;
    }
    if (file.size > _maxAttachmentSizeBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran lampiran maksimal 5 MB.')),
      );
      return;
    }
    setState(() => _attachment = file);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    final amount =
        double.tryParse(
          _amountCtrl.text.replaceAll(',', '.').replaceAll('.', ''),
        ) ??
        0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    if (widget.editId != null) {
      context.read<FinanceBloc>().add(
        FinanceLedgerUpdated(
          id: widget.editId!,
          date: _dateCtrl.text,
          categoryId: _categoryId,
          type: _type,
          amount: amount,
          description: _descCtrl.text,
          unitId: _unitId,
          attachmentPath: _attachment?.path,
          attachmentName: _attachment?.name,
        ),
      );
    } else {
      context.read<FinanceBloc>().add(
        FinanceLedgerCreated(
          date: _dateCtrl.text,
          categoryId: _categoryId!,
          type: _type,
          amount: amount,
          description: _descCtrl.text,
          unitId: _unitId,
          attachmentPath: _attachment?.path,
          attachmentName: _attachment?.name,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editId != null ? 'Edit Transaksi' : 'Transaksi Baru',
        ),
      ),
      body: BlocConsumer<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is FinanceFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit ? 'Transaksi diperbarui' : 'Transaksi dibuat',
                ),
              ),
            );
            context.pop(true);
          }
          if (state is FinanceFormFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const LoadingState(message: 'Memuat form...');
          }

          if (state is FinanceFormFailure) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<FinanceBloc>().add(
                FinanceLedgerFormRequested(editId: widget.editId),
              ),
            );
          }

          if (state is! FinanceFormLoaded) {
            return const SizedBox.shrink();
          }

          final categories = state.categories
              .where((c) => c.type == _type)
              .toList();
          final units = state.units.canSelectUnitForWrite
              ? state.units.units
              : const <FinanceUnitModel>[];

          if (!_prefilled && state.isEditMode && state.ledger != null) {
            _prefilled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _prefill(state.ledger!);
            });
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'income', label: Text('Pemasukan')),
                    ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: IconButton(
                      tooltip: 'Pilih tanggal',
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event_available_outlined),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Tanggal wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => _categoryId = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah (Rp)',
                    hintText: '0',
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                    final n = double.tryParse(
                      v.replaceAll(',', '.').replaceAll('.', ''),
                    );
                    if (n == null || n <= 0) return 'Jumlah harus lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Keterangan transaksi',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                if (units.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _unitId,
                    decoration: const InputDecoration(
                      labelText: 'Unit (opsional)',
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('— Tidak ada —'),
                      ),
                      ...units.map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.isPusat ? '${u.name} (Pusat)' : u.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => _unitId = v,
                  ),
                ],
                const SizedBox(height: 16),
                _AttachmentPicker(
                  attachment: _attachment,
                  existingAttachmentPath: state.ledger?.attachmentPath,
                  onPick: _pickAttachment,
                  onClear: () => setState(() => _attachment = null),
                ),
                const SizedBox(height: 24),
                if (state is FinanceFormSubmitting)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: Text(
                      widget.editId != null
                          ? 'Simpan Perubahan'
                          : 'Simpan Transaksi',
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({
    required this.attachment,
    required this.existingAttachmentPath,
    required this.onPick,
    required this.onClear,
  });

  final PlatformFile? attachment;
  final String? existingAttachmentPath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final selected = attachment;
    final hasExisting =
        existingAttachmentPath != null && existingAttachmentPath!.isNotEmpty;
    final label = selected?.name ?? (hasExisting ? 'Lampiran tersimpan' : null);
    final subtitle = selected != null
        ? _formatSize(selected.size)
        : (hasExisting
              ? existingAttachmentPath
              : 'PDF, JPG, atau PNG. Maks. 5 MB.');

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Lampiran (opsional)',
        prefixIcon: Icon(Icons.attach_file_outlined),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label ?? 'Belum ada lampiran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (selected != null)
            IconButton(
              tooltip: 'Hapus lampiran',
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(selected == null ? 'Pilih' : 'Ganti'),
          ),
        ],
      ),
    );
  }

  String _formatSize(int size) {
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (size >= 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '$size byte';
  }
}
