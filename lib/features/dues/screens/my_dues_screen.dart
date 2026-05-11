import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dues_bloc.dart';
import '../bloc/dues_event.dart';
import '../bloc/dues_state.dart';
import '../widgets/dues_card.dart';
import '../widgets/dues_summary_card.dart';

class MyDuesScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const MyDuesScreen({super.key});

  @override
  State<MyDuesScreen> createState() => _MyDuesScreenState();
}

class _MyDuesScreenState extends State<MyDuesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DuesBloc>().add(LoadMyDues());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iuran Saya')),
      body: BlocBuilder<DuesBloc, DuesState>(
        builder: (context, state) {
          if (state.status == DuesStatus.loading ||
              state.status == DuesStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == DuesStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage ?? 'Terjadi kesalahan'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<DuesBloc>().add(LoadMyDues()),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          } else if (!state.hasMember) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Profil anggota belum terhubung.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to profile
                    },
                    child: const Text('Hubungkan Profil'),
                  ),
                ],
              ),
            );
          } else if (state.payments.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<DuesBloc>().add(RefreshMyDues());
              },
              child: ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Belum ada data iuran.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DuesBloc>().add(RefreshMyDues());
            },
            child: ListView.builder(
              itemCount: state.payments.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  if (state.summary != null) {
                    return DuesSummaryCard(
                      summary: state.summary!,
                      defaultAmount: state.defaultAmount,
                    );
                  }
                  return const SizedBox();
                }
                final payment = state.payments[index - 1];
                return DuesCard(payment: payment);
              },
            ),
          );
        },
      ),
    );
  }
}
