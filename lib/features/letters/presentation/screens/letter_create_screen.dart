import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/widgets/loading_state.dart';
import '../bloc/letter_bloc.dart';
import '../bloc/letter_event.dart';
import '../bloc/letter_state.dart';

class LetterCreateScreen extends StatefulWidget {
  const LetterCreateScreen({super.key});

  @override
  State<LetterCreateScreen> createState() => _LetterCreateScreenState();
}

class _LetterCreateScreenState extends State<LetterCreateScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  int? _categoryId;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    context.read<LetterBloc>().add(const LetterCategoriesFetched());
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kategori terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<LetterBloc>().add(
      LetterCreated(
        categoryId: _categoryId!,
        subject: _subjectController.text.trim(),
        body: _bodyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Buat Surat',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<LetterBloc, LetterState>(
        listener: (context, state) {
          if (state is LetterCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Surat berhasil dibuat.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xFF22C55E),
              ),
            );
            context.pop();
          }
          if (state is LetterFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        },
        child: BlocBuilder<LetterBloc, LetterState>(
          builder: (context, state) {
            if (state is LetterLoading) {
              return const LoadingState(message: 'Membuat surat...');
            }

            final categories = state is LetterCategoriesLoaded
                ? state.categories
                : null;

            return FadeTransition(
              opacity: CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOut,
                      ),
                    ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1565C0).withValues(alpha: 0.1),
                            const Color(0xFF1565C0).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1565C0,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF1565C0),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Isi form berikut untuk membuat surat baru. Surat akan disimpan sebagai draft.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1565C0),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Category dropdown
                          _FormCard(
                            child: categories != null
                                ? DropdownButtonFormField<int>(
                                    decoration: const InputDecoration(
                                      labelText: 'Kategori Surat',
                                      labelStyle: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.grey,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                        borderSide: BorderSide(
                                          color: Color(0xFF1565C0),
                                          width: 2,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.category_outlined,
                                        color: Color(0xFF1565C0),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
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
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Pilih kategori surat';
                                      }
                                      return null;
                                    },
                                  )
                                : DropdownButtonFormField<int>(
                                    decoration: const InputDecoration(
                                      labelText: 'Kategori Surat',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.category_outlined),
                                    ),
                                    items: const [],
                                    onChanged: null,
                                  ),
                          ),

                          const SizedBox(height: 16),

                          // Subject field
                          _FormCard(
                            child: TextFormField(
                              controller: _subjectController,
                              decoration: const InputDecoration(
                                labelText: 'Perihal',
                                hintText: 'Tulis perihal surat',
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.grey,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFF1565C0),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.title_rounded,
                                  color: Color(0xFF1565C0),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Perihal harus diisi.';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Body field
                          _FormCard(
                            child: TextFormField(
                              controller: _bodyController,
                              maxLines: 10,
                              decoration: const InputDecoration(
                                labelText: 'Isi Surat',
                                hintText: 'Tulis isi surat...',
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.grey,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: Color(0xFF1565C0),
                                    width: 2,
                                  ),
                                ),
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Isi surat harus diisi.';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Submit button
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: FilledButton.icon(
                              onPressed: _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.save_outlined, size: 22),
                              label: const Text(
                                'Simpan Draft',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: child,
    );
  }
}
