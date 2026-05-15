import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../bloc/letter_bloc.dart';
import '../bloc/letter_event.dart';
import '../bloc/letter_state.dart';

class LetterDetailScreen extends StatefulWidget {
  const LetterDetailScreen({required this.id, super.key});

  final int id;

  @override
  State<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends State<LetterDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    context.read<LetterBloc>().add(LetterDetailFetched(widget.id));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<LetterBloc>().add(LetterDetailFetched(widget.id));
    _animationController.forward(from: 0);
  }

  static const _statusColors = {
    'draft': Color(0xFF6B7280),
    'submitted': AppColors.warning,
    'approved': AppColors.info,
    'sent': AppColors.success,
    'rejected': AppColors.error,
  };

  static const _statusLabels = {
    'draft': 'Draft',
    'submitted': 'Diajukan',
    'approved': 'Disetujui',
    'sent': 'Terkirim',
    'rejected': 'Ditolak',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<LetterBloc, LetterState>(
        listener: (context, state) {
          // Trigger animation once when detail loads — not inside builder
          if (state is LetterDetailLoaded) {
            _animationController.forward();
          }
        },
        builder: (context, state) {
          if (state is LetterLoading || state is LetterInitial) {
            return const LoadingState(message: 'Memuat detail surat...');
          }
          if (state is LetterFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final letter = (state as LetterDetailLoaded).letter;
          final statusColor =
              _statusColors[letter.status] ?? const Color(0xFF6B7280);
          final statusLabel = _statusLabels[letter.status] ?? letter.status;

          return CustomScrollView(
            slivers: [
              // Gradient app bar with decorative elements
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                title: const Text(
                  'Detail Surat',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          right: -30,
                          top: 24,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: 24,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 52, 20, 14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(
                                      0.0,
                                      0.5,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                  child: SlideTransition(
                                    position:
                                        Tween<Offset>(
                                          begin: const Offset(0, 0.2),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: _animationController,
                                            curve: const Interval(
                                              0.0,
                                              0.5,
                                              curve: Curves.easeOut,
                                            ),
                                          ),
                                        ),
                                    child: const Text(
                                      'Detail Surat',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        height: 1.08,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: _animationController,
                                    curve: const Interval(
                                      0.2,
                                      0.7,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: _HeaderBadge(
                                          label: letter.categoryName,
                                          background: Colors.white.withValues(
                                            alpha: 0.20,
                                          ),
                                          borderColor: Colors.transparent,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: _HeaderBadge(
                                          label: statusLabel,
                                          background: statusColor.withValues(
                                            alpha: 0.25,
                                          ),
                                          borderColor: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
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
                    ),
                  ),
                ),
              ),

              // Content with animations
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0.3,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header card with enhanced design
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.1),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (letter.number.isNotEmpty &&
                                    letter.number != '-') ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.tag_rounded,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'No. ${letter.number}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Text(
                                  letter.subject,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade200,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _MetaRow(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Dari',
                                  value: letter.creatorName,
                                ),
                                const SizedBox(height: 10),
                                _MetaRow(
                                  icon: Icons.business_outlined,
                                  label: 'Unit',
                                  value: letter.unitName,
                                ),
                                if (letter.createdAt.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _MetaRow(
                                    icon: Icons.access_time_rounded,
                                    label: 'Tanggal',
                                    value: letter.createdAt,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                // Status indicator bar
                                _StatusProgressBar(status: letter.status),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Body content with enhanced styling
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.article_outlined,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Isi Surat',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAFBFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: _LetterBodyPreview(html: letter.body),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Action buttons
                          _ActionButtons(letter: letter),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.label,
    required this.background,
    required this.borderColor,
  });

  final String label;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Status Progress Bar ──────────────────────────────────────────────────────

class _StatusProgressBar extends StatelessWidget {
  const _StatusProgressBar({required this.status});

  final String status;

  static const _steps = ['draft', 'submitted', 'approved', 'sent'];
  static const _stepLabels = {
    'draft': 'Draft',
    'submitted': 'Diajukan',
    'approved': 'Disetujui',
    'sent': 'Terkirim',
  };

  @override
  Widget build(BuildContext context) {
    if (status == 'rejected') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
            SizedBox(width: 10),
            Text(
              'Surat ditolak',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _steps.indexOf(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final isCompleted = stepIndex < currentIndex;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          // Step dot
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex <= currentIndex;
          final isCurrent = stepIndex == currentIndex;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 28 : 24,
                height: isCurrent ? 28 : 24,
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        )
                      : null,
                  color: isCompleted ? null : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 3,
                        )
                      : null,
                  boxShadow: isCompleted
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                _stepLabels[_steps[stepIndex]] ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: isCompleted ? AppColors.primary : Colors.grey,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _LetterBodyPreview extends StatefulWidget {
  const _LetterBodyPreview({required this.html});

  final String html;

  @override
  State<_LetterBodyPreview> createState() => _LetterBodyPreviewState();
}

class _LetterBodyPreviewState extends State<_LetterBodyPreview>
    with SingleTickerProviderStateMixin {
  static const _collapsedHeight = 220.0;
  bool _expanded = false;

  static const _baseStyle = TextStyle(
    fontSize: 15,
    height: 1.7,
    color: Color(0xFF333333),
  );

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.html.trim();
    if (trimmed.isEmpty) {
      return const SelectableText('(Tidak ada isi surat)', style: _baseStyle);
    }

    final canExpand = _plainTextLength(trimmed) > 520;
    final content = SelectableText.rich(
      TextSpan(style: _baseStyle, children: _parseHtml(trimmed)),
    );

    if (!canExpand) return content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: _expanded
                ? const BoxConstraints()
                : const BoxConstraints(maxHeight: _collapsedHeight),
            child: Stack(
              children: [
                ClipRect(child: content),
                if (!_expanded)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 64,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFFAFBFC).withValues(alpha: 0),
                              const Color(0xFFFAFBFC),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
            label: Text(
              _expanded ? 'Tampilkan lebih sedikit' : 'Baca selengkapnya',
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  int _plainTextLength(String source) {
    return _decodeHtml(
      source.replaceAll(RegExp(r'<[^>]+>'), ' '),
    ).replaceAll(RegExp(r'\s+'), ' ').trim().length;
  }

  List<InlineSpan> _parseHtml(String source) {
    final spans = <InlineSpan>[];
    final styleStack = <TextStyle>[_baseStyle];
    final tagPattern = RegExp(r'<[^>]+>');
    var cursor = 0;
    var orderedIndex = 1;

    void addText(String text) {
      final normalized = _decodeHtml(
        text,
      ).replaceAll(RegExp(r'[ \t\r\f]+'), ' ');
      if (normalized.isEmpty) return;
      spans.add(TextSpan(text: normalized, style: styleStack.last));
    }

    void addBreak({int count = 1}) {
      if (spans.isEmpty) return;
      final currentText = spans.last is TextSpan
          ? ((spans.last as TextSpan).text ?? '')
          : '';
      final breaks = '\n' * count;
      if (currentText.endsWith(breaks)) return;
      spans.add(TextSpan(text: breaks, style: styleStack.last));
    }

    for (final match in tagPattern.allMatches(source)) {
      addText(source.substring(cursor, match.start));
      final rawTag = match.group(0) ?? '';
      final tag = rawTag
          .replaceAll(RegExp(r'[<>/]'), '')
          .trim()
          .split(RegExp(r'\s+'))
          .first
          .toLowerCase();
      final closing = rawTag.startsWith('</');

      switch (tag) {
        case 'br':
          addBreak();
        case 'p':
        case 'div':
          if (closing) {
            addBreak(count: 2);
          } else if (spans.isNotEmpty) {
            addBreak();
          }
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          if (closing) {
            if (styleStack.length > 1) styleStack.removeLast();
            addBreak(count: 2);
          } else {
            if (spans.isNotEmpty) addBreak();
            styleStack.add(
              styleStack.last.copyWith(
                fontSize: tag == 'h1' ? 20 : 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF071A3A),
              ),
            );
          }
        case 'strong':
        case 'b':
          if (closing) {
            if (styleStack.length > 1) styleStack.removeLast();
          } else {
            styleStack.add(
              styleStack.last.copyWith(fontWeight: FontWeight.w800),
            );
          }
        case 'em':
        case 'i':
          if (closing) {
            if (styleStack.length > 1) styleStack.removeLast();
          } else {
            styleStack.add(
              styleStack.last.copyWith(fontStyle: FontStyle.italic),
            );
          }
        case 'u':
          if (closing) {
            if (styleStack.length > 1) styleStack.removeLast();
          } else {
            styleStack.add(
              styleStack.last.copyWith(decoration: TextDecoration.underline),
            );
          }
        case 'ul':
          if (closing) addBreak();
        case 'ol':
          if (closing) {
            orderedIndex = 1;
            addBreak();
          }
        case 'li':
          if (closing) {
            addBreak();
          } else {
            final before = source.substring(0, match.start);
            final inOrderedList =
                before.lastIndexOf('<ol') > before.lastIndexOf('</ol>');
            addBreak();
            addText(inOrderedList ? '${orderedIndex++}. ' : '- ');
          }
      }

      cursor = match.end;
    }
    addText(source.substring(cursor));

    while (spans.isNotEmpty &&
        spans.last is TextSpan &&
        (((spans.last as TextSpan).text ?? '').trim().isEmpty)) {
      spans.removeLast();
    }

    return spans.isEmpty
        ? const [TextSpan(text: '(Tidak ada isi surat)')]
        : spans;
  }

  String _decodeHtml(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.letter});

  final dynamic letter;

  @override
  Widget build(BuildContext context) {
    return switch (letter.status) {
      'draft' => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: FilledButton.icon(
          onPressed: () {
            context.read<LetterBloc>().add(LetterSubmitted(letter.id));
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
          ),
          icon: const Icon(Icons.send_rounded, size: 22),
          label: const Text(
            'Ajukan Surat',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ),
      'submitted' => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.warning.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  context.read<LetterBloc>().add(LetterApproved(letter.id));
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.success.withValues(alpha: 0.3),
                ),
                icon: const Icon(Icons.check_rounded, size: 22),
                label: const Text(
                  'Setujui',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<LetterBloc>().add(LetterRejected(letter.id));
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 22),
                label: const Text(
                  'Tolak',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
      _ => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: OutlinedButton.icon(
          onPressed: () {
            context.read<LetterBloc>().add(LetterArchived(letter.id));
            Navigator.of(context).pop();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.archive_outlined, size: 22),
          label: const Text(
            'Arsipkan Surat',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
    };
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
