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
      appBar: AppBar(title: const Text('Buat Aspirasi')),
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

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (categories != null)
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => _categoryId = value,
                        )
                      else
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: [],
                          onChanged: null,
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul',
                          hintText: 'Tulis judul aspirasi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Judul harus diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bodyController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Isi aspirasi',
                          hintText: 'Jelaskan aspirasi Anda',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Isi aspirasi harus diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                labelText: 'Tag',
                                hintText: 'contoh: fasilitas',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.label_outline_rounded),
                              ),
                              onFieldSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addTag,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  onDeleted: () {
                                    setState(() => _tags.remove(tag));
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Kirim anonim'),
                        subtitle: const Text(
                          'Nama Anda tidak akan ditampilkan.',
                        ),
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() => _isAnonymous = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Kirim Aspirasi'),
                      ),
                    ],
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
