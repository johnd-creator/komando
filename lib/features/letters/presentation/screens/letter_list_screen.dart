import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
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
  final Map<String, LetterListLoaded> _loadedBoxes = {};

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

  Future<void> _createLetter() async {
    await context.push(AppRoutes.letterCreate);
    _reload();
  }

  void _switchBox(String box) {
    if (_box == box) return;
    setState(() => _box = box);
    context.read<LetterBloc>().add(LetterBoxChanged(box));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocBuilder<LetterBloc, LetterState>(
        builder: (context, state) {
          if (state is LetterListLoaded) {
            _loadedBoxes[state.box] = state;
          }

          final cachedListState = _loadedBoxes[_box];
          final isInitialLoading =
              (state is LetterLoading || state is LetterInitial) &&
              cachedListState == null &&
              _loadedBoxes.isEmpty;

          if (isInitialLoading) {
            return const LoadingState(message: 'Memuat surat...');
          }
          if (state is LetterFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }
          final listState = state is LetterListLoaded && state.box == _box
              ? state
              : cachedListState;
          final isTabLoading =
              state is LetterLoading && cachedListState == null;

          return _LetterScaffold(
            selectedBox: _box,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
            onCreate: _createLetter,
            onSelectBox: (box) {
              final index = _boxes.indexOf(box);
              if (index >= 0 && _tabController.index != index) {
                _tabController.animateTo(index);
              }
              _switchBox(box);
            },
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: isTabLoading
                  ? const _LetterContentLoading()
                  : (listState?.items.isEmpty ?? true)
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                      children: [
                        _LetterEmptyCard(
                          title: _emptyTitle,
                          message: _emptyMessage,
                          onCreate: _createLetter,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                      itemCount:
                          listState!.items.length + (listState.hasMore ? 1 : 0),
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
    'outbox' => 'Gunakan tombol Buat Surat untuk membuat surat baru.',
    'approvals' => 'Surat yang perlu Anda setujui akan tampil di sini.',
    _ => 'Belum ada surat.',
  };
}

class _LetterScaffold extends StatelessWidget {
  const _LetterScaffold({
    required this.selectedBox,
    required this.onBack,
    required this.onCreate,
    required this.onSelectBox,
    required this.child,
  });

  final String selectedBox;
  final VoidCallback onBack;
  final VoidCallback onCreate;
  final ValueChanged<String> onSelectBox;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final panelTop = safeTop + 110;

    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFFF5F7FA))),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: panelTop + 36,
          child: const _LetterHeader(),
        ),
        Positioned(
          top: safeTop + 20,
          left: 12,
          right: 24,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                iconSize: 26,
                tooltip: 'Kembali',
              ),
              const SizedBox(width: 8),
              Text(
                'Surat',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: panelTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9FC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              children: [
                _LetterTabs(selectedBox: selectedBox, onSelect: onSelectBox),
                const Divider(height: 1, color: Color(0xFFE1E8F2)),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LetterHeader extends StatelessWidget {
  const _LetterHeader();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF096FDB), Color(0xFF0062CF), Color(0xFF0757B7)],
        ),
      ),
    );
  }
}

class _LetterTabs extends StatelessWidget {
  const _LetterTabs({required this.selectedBox, required this.onSelect});

  final String selectedBox;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          for (final box in _boxes)
            Expanded(
              child: _LetterTabButton(
                box: box,
                selected: selectedBox == box,
                onTap: () => onSelect(box),
              ),
            ),
        ],
      ),
    );
  }
}

class _LetterTabButton extends StatelessWidget {
  const _LetterTabButton({
    required this.box,
    required this.selected,
    required this.onTap,
  });

  final String box;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF096FDB);
    final foreground = selected ? primary : const Color(0xFF536683);

    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            left: 3,
            right: 3,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: selected
                        ? Border.all(color: const Color(0xFFE3EBF8))
                        : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF27446F,
                              ).withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_boxIcons[box], size: 22, color: foreground),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          _boxLabels[box]!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 82 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterEmptyCard extends StatelessWidget {
  const _LetterEmptyCard({
    required this.title,
    required this.message,
    required this.onCreate,
  });

  final String title;
  final String message;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Container(
      constraints: BoxConstraints(minHeight: (height * 0.58).clamp(430, 560)),
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF27446F).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Spacer(),
          const _LetterEmptyIllustration(),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF20222A),
              fontWeight: FontWeight.w800,
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF536683),
                fontWeight: FontWeight.w500,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
          const Spacer(flex: 2),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF096FDB),
                foregroundColor: Colors.white,
                elevation: 9,
                shadowColor: const Color(0xFF096FDB).withValues(alpha: 0.32),
                minimumSize: const Size(164, 56),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              icon: const Icon(Icons.edit_rounded, size: 24),
              label: const Text('Buat Surat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterContentLoading extends StatelessWidget {
  const _LetterContentLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 120),
      children: const [
        Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
        ),
      ],
    );
  }
}

class _LetterEmptyIllustration extends StatelessWidget {
  const _LetterEmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 138,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 136,
            height: 136,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAF3FF),
            ),
          ),
          Positioned(
            bottom: 24,
            child: Container(
              width: 98,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFBFD8FB),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.inbox_rounded,
                color: Color(0xFF7DAAEF),
                size: 52,
              ),
            ),
          ),
          Positioned(
            top: 48,
            child: Container(
              width: 60,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7DAAEF).withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final width in const [42.0, 50.0, 34.0]) ...[
                    Container(
                      width: width,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7E6FA),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 7),
                  ],
                ],
              ),
            ),
          ),
          const Positioned(
            top: 28,
            right: 22,
            child: Icon(
              Icons.near_me_rounded,
              color: Color(0xFF9FC2F5),
              size: 44,
            ),
          ),
          const Positioned(
            top: 52,
            left: 42,
            child: Icon(
              Icons.circle_outlined,
              color: Color(0xFF9FC2F5),
              size: 9,
            ),
          ),
          const Positioned(
            bottom: 58,
            right: 36,
            child: Icon(Icons.auto_awesome, color: Color(0xFF9FC2F5), size: 20),
          ),
          const Positioned(
            bottom: 74,
            left: 24,
            child: Icon(Icons.auto_awesome, color: Color(0xFF9FC2F5), size: 16),
          ),
        ],
      ),
    );
  }
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
