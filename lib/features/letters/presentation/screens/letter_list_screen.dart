import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
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
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late String _box;
  final Map<String, LetterListLoaded> _loadedBoxes = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
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
    _fadeController.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<LetterBloc>().add(LettersFetched(box: _box, refresh: true));
    _fadeController.forward(from: 0);
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
    _fadeController.forward(from: 0);
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
                  : FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _fadeController,
                        curve: Curves.easeOut,
                      ),
                      child: listState == null || listState.items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                24,
                                20,
                                22,
                              ),
                              children: [
                                _LetterEmptyCard(
                                  box: _box,
                                  onCreate: _createLetter,
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                20,
                                16,
                                96,
                              ),
                              itemCount:
                                  listState.items.length +
                                  (listState.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= listState.items.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: TextButton.icon(
                                        onPressed: _loadMore,
                                        icon: const Icon(
                                          Icons.expand_more_rounded,
                                        ),
                                        label: const Text('Muat lagi'),
                                      ),
                                    ),
                                  );
                                }
                                return AnimatedOpacity(
                                  duration: Duration(
                                    milliseconds: 150 + (index * 30),
                                  ),
                                  opacity: 1.0,
                                  child: _LetterCard(
                                    letter: listState.items[index],
                                    isLast: index == listState.items.length - 1,
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _LetterScaffold extends StatelessWidget {
  const _LetterScaffold({
    required this.selectedBox,
    required this.onBack,
    required this.onSelectBox,
    required this.child,
  });

  final String selectedBox;
  final VoidCallback onBack;
  final ValueChanged<String> onSelectBox;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final panelTop = safeTop + 120; // Reduced from 140

    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFFF5F7FA))),
        // Enhanced Header with gradient and decorations
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: panelTop + 36,
          child: _EnhancedLetterHeader(
            selectedBox: selectedBox,
            onBack: onBack,
          ),
        ),
        // Content panel
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

class _EnhancedLetterHeader extends StatelessWidget {
  const _EnhancedLetterHeader({
    required this.selectedBox,
    required this.onBack,
  });

  final String selectedBox;
  final VoidCallback onBack;

  String get _headerSubtitle => switch (selectedBox) {
    'inbox' => 'Surat masuk yang ditujukan untuk Anda',
    'outbox' => 'Daftar surat yang telah Anda buat',
    'approvals' => 'Surat yang memerlukan persetujuan Anda',
    _ => 'Kelola surat organisasi',
  };

  IconData get _headerIcon => switch (selectedBox) {
    'inbox' => Icons.inbox_rounded,
    'outbox' => Icons.outbox_rounded,
    'approvals' => Icons.approval_rounded,
    _ => Icons.mail_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF1E88E5)],
            ),
          ),
        ),
        // Decorative circles
        Positioned(
          right: -30,
          top: 20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          right: 40,
          bottom: 60,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          left: -20,
          bottom: 30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              8,
              8,
              20,
              16,
            ), // Reduced top and bottom padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and title row
                Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                      iconSize: 24, // Reduced from 26
                      tooltip: 'Kembali',
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Surat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20, // Reduced from 24
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    // Action button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Cari',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Reduced from Spacer()
                // Subtitle with icon
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(_headerIcon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _boxLabels[selectedBox] ?? 'Surat',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17, // Reduced from 18
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3), // Reduced from 4
                            Text(
                              _headerSubtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12, // Reduced from 13
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
  const _LetterEmptyCard({required this.box, required this.onCreate});

  final String box;
  final VoidCallback onCreate;

  // Per-box config
  static const _titles = {
    'inbox': 'Kotak Masuk Kosong',
    'outbox': 'Belum Ada Surat Keluar',
    'approvals': 'Tidak Ada Perlu Disetujui',
  };

  static const _messages = {
    'inbox':
        'Anda belum menerima surat apapun.\nSurat yang masuk akan tampil di sini.',
    'outbox':
        'Anda belum pernah membuat surat.\nMulai buat surat pertama Anda sekarang.',
    'approvals':
        'Tidak ada surat yang menunggu\npersetujuan dari Anda saat ini.',
  };

  static const _tips = {
    'inbox': 'Surat masuk dikirim oleh pengurus atau anggota lain kepada Anda.',
    'outbox':
        'Buat surat baru dan ajukan untuk dikirim ke penerima yang dituju.',
    'approvals':
        'Surat yang memerlukan tanda tangan atau persetujuan Anda akan muncul di sini.',
  };

  static const _tipIcons = {
    'inbox': Icons.info_outline_rounded,
    'outbox': Icons.edit_note_rounded,
    'approvals': Icons.how_to_reg_outlined,
  };

  static const _tipColors = {
    'inbox': Color(0xFF3B82F6),
    'outbox': Color(0xFF8B5CF6),
    'approvals': Color(0xFF059669),
  };

  static const _illustrationIcons = {
    'inbox': Icons.inbox_rounded,
    'outbox': Icons.outbox_rounded,
    'approvals': Icons.approval_rounded,
  };

  bool get _showCreateButton => box == 'inbox' || box == 'outbox';

  @override
  Widget build(BuildContext context) {
    final title = _titles[box] ?? 'Belum ada surat';
    final message = _messages[box] ?? 'Belum ada data.';
    final tip = _tips[box] ?? '';
    final tipIcon = _tipIcons[box] ?? Icons.info_outline_rounded;
    final tipColor = _tipColors[box] ?? const Color(0xFF3B82F6);
    final illustrationIcon =
        _illustrationIcons[box] ?? Icons.mail_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1E8F2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF27446F).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration
          _LetterEmptyIllustration(icon: illustrationIcon, color: tipColor),
          const SizedBox(height: 24),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A365D),
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),

          // Info card — specific per tab
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tipColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tipColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tipColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tipIcon, color: tipColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 12,
                      color: tipColor.withValues(alpha: 0.9),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Create button (only for inbox & outbox)
          if (_showCreateButton) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onCreate,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Buat Surat Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
  const _LetterEmptyIllustration({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.04),
                ],
              ),
            ),
          ),
          // Main icon container
          Positioned(
            bottom: 22,
            child: Container(
              width: 90,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.8), color],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
          // Floating document card
          Positioned(
            top: 28,
            child: Container(
              width: 64,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final w in [36.0, 46.0, 38.0, 28.0]) ...[
                    Container(
                      width: w,
                      height: 5,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                ],
              ),
            ),
          ),
          // Decorative dots
          Positioned(
            top: 38,
            left: 28,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            bottom: 62,
            right: 24,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Sparkles
          Positioned(
            top: 16,
            right: 28,
            child: Icon(
              Icons.auto_awesome,
              color: color.withValues(alpha: 0.4),
              size: 16,
            ),
          ),
          Positioned(
            bottom: 22,
            left: 18,
            child: Icon(
              Icons.auto_awesome,
              color: color.withValues(alpha: 0.3),
              size: 12,
            ),
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
    'draft': Color(0xFF6B7280),
    'submitted': Color(0xFFF97316),
    'approved': Color(0xFF3B82F6),
    'sent': Color(0xFF22C55E),
    'rejected': Color(0xFFEF4444),
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
    final color = _statusColors[letter.status] ?? const Color(0xFF6B7280);
    final label = _statusLabels[letter.status] ?? letter.status;
    final icon = _statusIcons[letter.status] ?? Icons.mail_outline_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(AppRoutes.letterDetail(letter.id)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status icon circle with gradient
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              letter.subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _EnhancedStatusChip(label: label, color: color),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(
                                    0xFF1565C0,
                                  ).withValues(alpha: 0.1),
                                  const Color(
                                    0xFF1565C0,
                                  ).withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFF1565C0,
                                ).withValues(alpha: 0.2),
                              ),
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.attach_file_rounded,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '${letter.creatorName} · ${letter.createdAt}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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

// Enhanced status chip with gradient
class _EnhancedStatusChip extends StatelessWidget {
  const _EnhancedStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
