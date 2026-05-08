import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const AdminMembersFetched());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    context.read<AdminBloc>().add(
      AdminMembersFetched(
        search: _searchCtrl.text.trim().isEmpty
            ? null
            : _searchCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Anggota'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama, NPA, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
        ),
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminInitial) return const SizedBox.shrink();

          if (state is AdminLoading) {
            return LoadingState(message: state.message);
          }

          if (state is AdminFailure) {
            return ErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<AdminBloc>().add(const AdminMembersFetched()),
            );
          }

          if (state is! AdminMembersLoaded) return const SizedBox.shrink();

          final page = state.page;

          if (page.items.isEmpty) {
            return const EmptyState(
              title: 'Tidak ada anggota',
              message: 'Coba gunakan kata kunci pencarian berbeda.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<AdminBloc>().add(const AdminMembersFetched()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: page.items.length + (page.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index >= page.items.length) {
                  return Center(
                    child: TextButton(
                      onPressed: () => context.read<AdminBloc>().add(
                        AdminMembersFetched(
                          search: _searchCtrl.text.trim().isEmpty
                              ? null
                              : _searchCtrl.text.trim(),
                          page: page.currentPage + 1,
                        ),
                      ),
                      child: const Text('Muat lagi'),
                    ),
                  );
                }

                final member = page.items[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(member.name.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(member.name),
                  subtitle: Text(
                    'NPA: ${member.npa}${member.unitName != null ? ' · ${member.unitName}' : ''}',
                  ),
                  trailing: member.role != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            member.role!,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        )
                      : null,
                  onTap: () =>
                      context.push(AppRoutes.adminMemberDetail(member.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
