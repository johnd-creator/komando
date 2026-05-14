import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/widgets/loading_state.dart';
import '../bloc/aspiration_bloc.dart';
import '../bloc/aspiration_event.dart';
import '../bloc/aspiration_state.dart';

class AspirationCreateScreen extends StatefulWidget {
  const AspirationCreateScreen({super.key});

  @override
  State<AspirationCreateScreen> createState() => _AspirationCreateScreenState();
}

class _AspirationCreateScreenState extends State<AspirationCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();
  bool _isAnonymous = false;
  final List<String> _tags = [];
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    context.read<AspirationBloc>().add(const AspirationCategoriesFetched());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
      );
      return;
    }

    context.read<AspirationBloc>().add(
      AspirationCreated(
        categoryId: _categoryId!,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        tags: _tags,
        isAnonymous: _isAnonymous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocListener<AspirationBloc, AspirationState>(
        listener: (context, state) {
          if (state is AspirationCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Aspirasi berhasil dikirim.')),
            );
            context.pop();
          }
          if (state is AspirationFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<AspirationBloc, AspirationState>(
          builder: (context, state) {
            if (state is AspirationLoading) {
              return const LoadingState(message: 'Mengirim aspirasi...');
            }

            final categories = state is AspirationCategoriesLoaded
                ? state.categories
                : null;

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _CreateHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
                  sliver: SliverToBoxAdapter(
                    child: _CreateFormCard(
                      formKey: _formKey,
                      categories: categories,
                      categoryId: _categoryId,
                      titleController: _titleController,
                      bodyController: _bodyController,
                      tagController: _tagController,
                      tags: _tags,
                      isAnonymous: _isAnonymous,
                      onCategoryChanged: (value) {
                        setState(() => _categoryId = value);
                      },
                      onAddTag: _addTag,
                      onRemoveTag: (tag) {
                        setState(() => _tags.remove(tag));
                      },
                      onAnonymousChanged: (value) {
                        setState(() => _isAnonymous = value);
                      },
                      onSubmit: _submit,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }
}

class _CreateHeader extends StatelessWidget {
  const _CreateHeader();

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        SizedBox(
          height: safeTop + 218,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/bg-asset.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF096FDB).withValues(alpha: 0.98),
                      const Color(0xFF075EC4).withValues(alpha: 0.95),
                      const Color(0xFF064FA8).withValues(alpha: 0.98),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -1,
          child: Container(
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
        ),
        Positioned(
          top: safeTop + 12,
          left: 8,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
            iconSize: 30,
            tooltip: 'Kembali',
          ),
        ),
        Positioned(
          top: safeTop + 62,
          left: 22,
          right: 22,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.add_comment_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buat Aspirasi',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sampaikan aspirasi dengan jelas agar mudah ditindaklanjuti.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateFormCard extends StatelessWidget {
  const _CreateFormCard({
    required this.formKey,
    required this.categories,
    required this.categoryId,
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.tags,
    required this.isAnonymous,
    required this.onCategoryChanged,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.onAnonymousChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final List<dynamic>? categories;
  final int? categoryId;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final List<String> tags;
  final bool isAnonymous;
  final ValueChanged<int?> onCategoryChanged;
  final VoidCallback onAddTag;
  final ValueChanged<String> onRemoveTag;
  final ValueChanged<bool> onAnonymousChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _FormSection(
              title: 'Detail Aspirasi',
              icon: Icons.edit_note_rounded,
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: categoryId,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: 'Kategori',
                      hint: 'Pilih kategori aspirasi',
                      icon: Icons.category_outlined,
                    ),
                    items:
                        categories
                            ?.map(
                              (c) => DropdownMenuItem<int>(
                                value: c.id as int,
                                child: Text(c.name as String),
                              ),
                            )
                            .toList() ??
                        const [],
                    onChanged: categories == null ? null : onCategoryChanged,
                    validator: (value) {
                      if (value == null) return 'Kategori harus dipilih.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: titleController,
                    decoration: _inputDecoration(
                      label: 'Judul',
                      hint: 'Contoh: Penambahan fasilitas ruang kerja',
                      icon: Icons.title_rounded,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Judul harus diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: bodyController,
                    maxLines: 7,
                    minLines: 5,
                    decoration: _inputDecoration(
                      label: 'Isi aspirasi',
                      hint: 'Jelaskan masalah, kebutuhan, dan usulan solusi.',
                      icon: Icons.article_outlined,
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Isi aspirasi harus diisi.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Tag dan Privasi',
              icon: Icons.tune_rounded,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: tagController,
                          decoration: _inputDecoration(
                            label: 'Tag',
                            hint: 'contoh: fasilitas',
                            icon: Icons.label_outline_rounded,
                          ),
                          onFieldSubmitted: (_) => onAddTag(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox.square(
                        dimension: 52,
                        child: IconButton.filled(
                          onPressed: onAddTag,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF096FDB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags
                            .map(
                              (tag) => Chip(
                                label: Text('#$tag'),
                                deleteIcon: const Icon(Icons.close_rounded),
                                onDeleted: () => onRemoveTag(tag),
                                backgroundColor: const Color(0xFFEAF4FF),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF096FDB),
                                  fontWeight: FontWeight.w700,
                                ),
                                side: BorderSide.none,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE1E8F2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4FF),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.visibility_off_outlined,
                            color: Color(0xFF096FDB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kirim anonim',
                                style: TextStyle(
                                  color: Color(0xFF0B1B37),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Nama Anda tidak akan ditampilkan.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isAnonymous,
                          onChanged: onAnonymousChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF096FDB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text('Kirim Aspirasi'),
              ),
            ),
          ],
        ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A4667).withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF096FDB), size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0B1B37),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required String hint,
  required IconData icon,
  bool alignLabelWithHint = false,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: alignLabelWithHint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF8FAFD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDDE7F4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDDE7F4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF096FDB), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFB42318)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFB42318)),
    ),
  );
}
