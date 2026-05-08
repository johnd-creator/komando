import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/admin_repository.dart';
import '../../../../core/api/api_error_handler.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  String? _error;
  List<String> _availableReports = [];

  static const _reportTypes = [
    'members',
    'dues',
    'finance',
    'mutations',
    'aspirations',
    'growth',
  ];

  static const _reportLabels = {
    'members': 'Laporan Anggota',
    'dues': 'Laporan Iuran',
    'finance': 'Laporan Keuangan',
    'mutations': 'Laporan Mutasi',
    'aspirations': 'Laporan Aspirasi',
    'growth': 'Laporan Pertumbuhan',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _availableReports = _reportTypes;
    _loading = false;
    if (mounted) setState(() {});
  }

  Future<void> _requestExport(String type) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<AdminRepository>();
      final req = await repo.requestExport(type);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Laporan "${_reportLabels[type] ?? type}" diminta. Status: ${req.status}',
          ),
        ),
      );
    } catch (e) {
      _error = ApiErrorHandler.getMessage(e);
    }
    _loading = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: Builder(
        builder: (context) {
          if (_loading) return const LoadingState(message: 'Memuat laporan...');
          if (_error != null) {
            return ErrorState(message: _error!, onRetry: _load);
          }

          if (_availableReports.isEmpty) {
            return const EmptyState(
              title: 'Belum ada laporan',
              message: 'Laporan ekspor akan tampil di sini.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _availableReports.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final type = _availableReports[index];
              final label = _reportLabels[type] ?? type;

              return ListTile(
                leading: CircleAvatar(child: Icon(_iconFor(type))),
                title: Text(label),
                subtitle: Text('Ekspor data $label'),
                trailing: FilledButton.tonalIcon(
                  onPressed: () => _requestExport(type),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Ekspor'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'members' => Icons.people,
      'dues' => Icons.payments,
      'finance' => Icons.account_balance_wallet,
      'mutations' => Icons.swap_horiz,
      'aspirations' => Icons.lightbulb,
      'growth' => Icons.trending_up,
      _ => Icons.description,
    };
  }
}
