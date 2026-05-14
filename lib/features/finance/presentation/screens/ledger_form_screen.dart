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
  bool _isSubmitting = false;
  PlatformFile? _attachment;
  FinanceFormLoaded? _lastLoadedState;

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

    setState(() => _isSubmitting = true);
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
      backgroundColor: const Color(0xFFF3F7FC),
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
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is FinanceLoading) {
            return _FormScaffold(
              title: widget.editId != null
                  ? 'Edit Transaksi'
                  : 'Transaksi Baru',
              subtitle: widget.editId != null
                  ? 'Perbarui data transaksi keuangan.'
                  : 'Catat pemasukan atau pengeluaran baru.',
              child: const LoadingState(message: 'Memuat form...'),
            );
          }

          if (state is FinanceFormFailure) {
            return _FormScaffold(
              title: widget.editId != null
                  ? 'Edit Transaksi'
                  : 'Transaksi Baru',
              subtitle: widget.editId != null
                  ? 'Perbarui data transaksi keuangan.'
                  : 'Catat pemasukan atau pengeluaran baru.',
              child: ErrorState(
                message: state.message,
                onRetry: () => context.read<FinanceBloc>().add(
                  FinanceLedgerFormRequested(editId: widget.editId),
                ),
              ),
            );
          }

          if (state is FinanceFormLoaded) {
            _lastLoadedState = state;
          }

          final formState = state is FinanceFormLoaded
              ? state
              : (state is FinanceFormSubmitting ? _lastLoadedState : null);

          if (formState == null) {
            return const SizedBox.shrink();
          }

          final categories = formState.categories
              .where((c) => c.type == _type)
              .toList();
          final units = formState.units.canSelectUnitForWrite
              ? formState.units.units
              : const <FinanceUnitModel>[];

          if (!_prefilled && formState.isEditMode && formState.ledger != null) {
            _prefilled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _prefill(formState.ledger!);
            });
          }

          return _FormScaffold(
            title: widget.editId != null ? 'Edit Transaksi' : 'Transaksi Baru',
            subtitle: widget.editId != null
                ? 'Perbarui data transaksi keuangan.'
                : 'Catat pemasukan atau pengeluaran baru.',
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _FormSection(
                    title: 'Jenis Transaksi',
                    icon: Icons.swap_vert_rounded,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'income',
                          icon: Icon(Icons.arrow_downward_rounded),
                          label: Text('Pemasukan'),
                        ),
                        ButtonSegment(
                          value: 'expense',
                          icon: Icon(Icons.arrow_upward_rounded),
                          label: Text('Pengeluaran'),
                        ),
                      ],
                      selected: {_type},
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFF126ED3);
                              }
                              return const Color(0xFFF6F9FD);
                            }),
                        foregroundColor:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              return const Color(0xFF51627A);
                            }),
                        side: WidgetStateProperty.all(
                          const BorderSide(color: Color(0xFFDDE8F5)),
                        ),
                      ),
                      onSelectionChanged: (v) {
                        setState(() {
                          _type = v.first;
                          _categoryId = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FormSection(
                    title: 'Detail Transaksi',
                    icon: Icons.receipt_long_rounded,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _dateCtrl,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: _inputDecoration(
                            label: 'Tanggal',
                            hint: 'YYYY-MM-DD',
                            icon: Icons.calendar_today_rounded,
                            suffix: IconButton(
                              tooltip: 'Pilih tanggal',
                              onPressed: _pickDate,
                              icon: const Icon(Icons.event_available_outlined),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Tanggal wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          initialValue: _categoryId,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            label: 'Kategori',
                            icon: Icons.category_rounded,
                          ),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: _DropdownText(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _amountCtrl,
                          decoration: _inputDecoration(
                            label: 'Jumlah (Rp)',
                            hint: '0',
                            icon: Icons.payments_rounded,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Jumlah wajib diisi';
                            }
                            final n = double.tryParse(
                              v.replaceAll(',', '.').replaceAll('.', ''),
                            );
                            if (n == null || n <= 0) {
                              return 'Jumlah harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: _inputDecoration(
                            label: 'Deskripsi',
                            hint: 'Keterangan transaksi',
                            icon: Icons.description_rounded,
                          ),
                          minLines: 2,
                          maxLines: 4,
                        ),
                        if (units.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<int>(
                            initialValue: _unitId,
                            isExpanded: true,
                            decoration: _inputDecoration(
                              label: 'Unit (opsional)',
                              icon: Icons.business_rounded,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: _DropdownText('Tidak ada'),
                              ),
                              ...units.map(
                                (u) => DropdownMenuItem(
                                  value: u.id,
                                  child: _DropdownText(
                                    u.isPusat ? '${u.name} (Pusat)' : u.name,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _unitId = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FormSection(
                    title: 'Lampiran',
                    icon: Icons.attach_file_rounded,
                    child: _AttachmentPicker(
                      attachment: _attachment,
                      existingAttachmentPath: formState.ledger?.attachmentPath,
                      onPick: _pickAttachment,
                      onClear: () => setState(() => _attachment = null),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        widget.editId != null
                            ? 'Simpan Perubahan'
                            : 'Simpan Transaksi',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF126ED3),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFBFD5F7),
                        disabledForegroundColor: Colors.white,
                        textStyle: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  String? hint,
  IconData? icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF6F9FD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFDDE8F5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFDDE8F5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF126ED3), width: 1.4),
    ),
  );
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LedgerFormHeader(title: title, subtitle: subtitle),
        Expanded(child: child),
      ],
    );
  }
}

class _LedgerFormHeader extends StatelessWidget {
  const _LedgerFormHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.paddingOf(context).top + 196,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B67C8), Color(0xFF228CE5)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.24,
            child: Transform.scale(
              scale: 1.18,
              child: Image.asset(
                'assets/bg-asset.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Keuangan',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE8F5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3A75).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF126ED3), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF071A3A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DropdownText extends StatelessWidget {
  const _DropdownText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
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
