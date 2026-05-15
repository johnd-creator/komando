import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../data/models/admin_model.dart';
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
    final query = _searchCtrl.text.trim();
    context.read<AdminBloc>().add(
      AdminMembersFetched(search: query.isEmpty ? null : query),
    );
  }

  void _refresh() {
    _searchCtrl.clear();
    context.read<AdminBloc>().add(const AdminMembersFetched());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          final isInitialLoading =
              state is AdminInitial || state is AdminLoading;

          return Column(
            children: [
              _MemberListHeader(
                controller: _searchCtrl,
                onSearch: _search,
                onClear: _refresh,
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (isInitialLoading) {
                      final message = state is AdminLoading
                          ? state.message
                          : 'Memuat data anggota...';
                      return LoadingState(message: message);
                    }

                    if (state is AdminFailure) {
                      return ErrorState(
                        message: state.message,
                        onRetry: _refresh,
                      );
                    }

                    if (state is! AdminMembersLoaded) {
                      return const SizedBox.shrink();
                    }

                    final page = state.page;
                    if (page.items.isEmpty) {
                      return const EmptyState(
                        title: 'Tidak ada anggota',
                        message: 'Coba gunakan kata kunci pencarian berbeda.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        itemCount: page.items.length + (page.hasMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index >= page.items.length) {
                            return _LoadMoreButton(
                              onPressed: () {
                                final query = _searchCtrl.text.trim();
                                context.read<AdminBloc>().add(
                                  AdminMembersFetched(
                                    search: query.isEmpty ? null : query,
                                    page: page.currentPage + 1,
                                  ),
                                );
                              },
                            );
                          }

                          final member = page.items[index];
                          return _MemberCard(member: member);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberListHeader extends StatelessWidget {
  const _MemberListHeader({
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDDE8F5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFF071A3A),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Data Anggota',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF071A3A),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari nama, NPA, email...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Bersihkan pencarian',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
              filled: true,
              fillColor: const Color(0xFFF6F9FD),
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
                borderSide: const BorderSide(
                  color: Color(0xFF126ED3),
                  width: 1.4,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final AdminMemberModel member;

  @override
  Widget build(BuildContext context) {
    final initial = member.name.trim().isEmpty
        ? '?'
        : member.name.trim()[0].toUpperCase();
    final status = member.status ?? 'aktif';

    return InkWell(
      onTap: () => context.push(AppRoutes.adminMemberDetail(member.id)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDDE8F5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B3A75).withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _InitialAvatar(text: initial),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF071A3A),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      _StatusChip(label: status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetaChip(icon: Icons.badge_outlined, label: member.npa),
                      if (member.unitName != null)
                        _MetaChip(
                          icon: Icons.apartment_rounded,
                          label: member.unitName!,
                        ),
                      if (member.role != null)
                        _MetaChip(
                          icon: Icons.verified_user_outlined,
                          label: member.role!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A9AAF)),
          ],
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFF126ED3),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2ECF7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5C6D86)),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF5C6D86),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    final active = normalized == 'aktif' || normalized == 'active';
    final color = active ? const Color(0xFF159B56) : const Color(0xFFE18A00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        active ? 'Aktif' : label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.expand_more_rounded),
          label: const Text('Muat lagi'),
        ),
      ),
    );
  }
}
