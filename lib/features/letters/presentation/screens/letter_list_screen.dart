import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../../../shared/presentation/widgets/section_header.dart';
import '../../data/models/letter_model.dart';
import '../bloc/letter_bloc.dart';
import '../bloc/letter_event.dart';
import '../bloc/letter_state.dart';

const _boxes = ['inbox', 'outbox', 'approvals'];
const _boxLabels = {
  'inbox': 'Masuk',
  'outbox': 'Keluar',
  'approvals': 'Approval',
};
const _boxIcons = {
  'inbox': Icons.move_to_inbox_rounded,
  'outbox': Icons.outbox_rounded,
  'approvals': Icons.approval_rounded,
};

class LetterListScreen extends StatefulWidget {
  const LetterListScreen({this.initialBox = 'inbox', super.key});

  final String initialBox;

  @override
  State<LetterListScreen> createState() => _LetterListScreenState();
}

class _LetterListScreenState extends State<LetterListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _box;

  @override
  void initState() {
    super.initState();
    _box = widget.initialBox;
    final initialIndex = _boxes.indexOf(_box).clamp(0, 2);
    _tabController = TabController(
      length: _boxes.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _switchBox(_boxes[_tabController.index]);
      }
    });
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<LetterBloc>().add(LettersFetched(box: _box, refresh: true));
  }

  void _loadMore() {
    context.read<LetterBloc>().add(LettersFetched(box: _box));
  }

  void _switchBox(String box) {
    setState(() => _box = box);
    context.read<LetterBloc>().add(LetterBoxChanged(box));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.letterCreate);
          _reload();
        },
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text(
          'Buat Surat',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocBuilder<LetterBloc, LetterState>(
        builder: (context, state) {
          if (state is LetterLoading || state is LetterInitial) {
            return const LoadingState(message: 'Memuat surat...');
          }
          if (state is LetterFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }
          final listState = state as LetterListLoaded;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                // ── Header dengan TabBar ──────────────────────────────
                FeaturePageHeader(
                  title: 'Surat',
                  icon: Icons.mail_outline_rounded,
                  subtitle: 'Kelola surat masuk dan keluar',
                  contentTopOffset: 6,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(42),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      tabs: _boxes
                          .map(
                            (b) => Tab(
                              height: 42,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_boxIcons[b]!, size: 16),
                                  const SizedBox(width: 6),
                                  Text(_boxLabels[b]!),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),

                // ── List content ──────────────────────────────────────
                if (listState.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 96, 16, 120),
                      child: EmptyState(
                        title: _emptyTitle,
                        message: _emptyMessage,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    sliver: SliverList.builder(
                      itemCount:
                          listState.items.length + (listState.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= listState.items.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: TextButton.icon(
                                onPressed: _loadMore,
                                icon: const Icon(Icons.expand_more_rounded),
                                label: const Text('Muat lagi'),
                              ),
                            ),
                          );
                        }
                        return _LetterCard(
                          letter: listState.items[index],
                          isLast: index == listState.items.length - 1,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String get _emptyTitle => switch (_box) {
    'inbox' => 'Belum ada surat masuk',
    'outbox' => 'Belum ada surat keluar',
    'approvals' => 'Belum ada surat perlu approval',
    _ => 'Belum ada surat',
  };

  String get _emptyMessage => switch (_box) {
    'inbox' => 'Surat yang dikirim kepada Anda akan tampil di sini.',
    'outbox' => 'Gunakan tombol Buat untuk membuat surat baru.',
    'approvals' => 'Surat yang perlu Anda setujui akan tampil di sini.',
    _ => 'Belum ada surat.',
  };
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({required this.letter, this.isLast = false});

  final LetterModel letter;
  final bool isLast;

  static const _statusColors = {
    'draft': Colors.grey,
    'submitted': Colors.orange,
    'approved': Colors.blue,
    'sent': Colors.green,
    'rejected': Colors.red,
  };

  static const _statusLabels = {
    'draft': 'Draft',
    'submitted': 'Diajukan',
    'approved': 'Disetujui',
    'sent': 'Terkirim',
    'rejected': 'Ditolak',
  };

  static const _statusIcons = {
    'draft': Icons.edit_note_rounded,
    'submitted': Icons.pending_rounded,
    'approved': Icons.check_circle_outline_rounded,
    'sent': Icons.send_rounded,
    'rejected': Icons.cancel_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[letter.status] ?? Colors.grey;
    final label = _statusLabels[letter.status] ?? letter.status;
    final icon = _statusIcons[letter.status] ?? Icons.mail_outline_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(AppRoutes.letterDetail(letter.id)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status icon circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              letter.subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(label: label, color: color),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1565C0,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              letter.categoryName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (letter.hasAttachments) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${letter.creatorName} · ${letter.createdAt}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
