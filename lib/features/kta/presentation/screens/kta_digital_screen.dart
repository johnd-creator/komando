import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../bloc/kta_bloc.dart';
import '../bloc/kta_event.dart';
import '../bloc/kta_state.dart';

class KtaDigitalScreen extends StatefulWidget {
  const KtaDigitalScreen({super.key});

  @override
  State<KtaDigitalScreen> createState() => _KtaDigitalScreenState();
}

class _KtaDigitalScreenState extends State<KtaDigitalScreen> {
  @override
  void initState() {
    super.initState();
    context.read<KtaBloc>().add(const KtaCardRequested());
  }

  void _reload() {
    context.read<KtaBloc>().add(const KtaCardRequested());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('KTA Digital')),
      body: BlocBuilder<KtaBloc, KtaState>(
        builder: (context, state) {
          if (state is KtaLoading || state is KtaInitial) {
            return const LoadingState(message: 'Memuat KTA digital...');
          }

          if (state is KtaFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final loaded = state as KtaLoaded;
          final card = loaded.card;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  color: colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1Komando',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          card.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          card.number,
                          style: TextStyle(
                            color: colorScheme.onPrimary.withValues(
                              alpha: 0.82,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(card.status)),
                            Chip(label: Text(card.unit)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (loaded.qrBytes == null)
                          const Icon(Icons.qr_code_2_rounded, size: 112)
                        else
                          Image.memory(
                            loaded.qrBytes!,
                            width: 160,
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        const SizedBox(height: 12),
                        Text(
                          card.hasQr
                              ? 'QR verifikasi anggota'
                              : 'QR belum tersedia',
                        ),
                        const SizedBox(height: 8),
                        Text('Berlaku sampai: ${card.validUntil}'),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: card.canDownloadPdf ? () {} : null,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Unduh PDF'),
                        ),
                      ],
                    ),
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
