import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../../../shared/presentation/widgets/section_header.dart';
import '../../data/models/aspiration_model.dart';
import '../bloc/aspiration_bloc.dart';
import '../bloc/aspiration_event.dart';
import '../bloc/aspiration_state.dart';

class AspirationDetailScreen extends StatefulWidget {
  const AspirationDetailScreen({required this.id, super.key});

  final int id;

  @override
  State<AspirationDetailScreen> createState() => _AspirationDetailScreenState();
}

class _AspirationDetailScreenState extends State<AspirationDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AspirationBloc>().add(AspirationDetailFetched(widget.id));
  }

  void _reload() {
    context.read<AspirationBloc>().add(AspirationDetailFetched(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocBuilder<AspirationBloc, AspirationState>(
        builder: (context, state) {
          if (state is AspirationLoading || state is AspirationInitial) {
            return const LoadingState(message: 'Memuat detail aspirasi...');
          }
          if (state is AspirationFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final aspiration = (state as AspirationDetailLoaded).aspiration;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                // ── Header (same style as Iuran) ──────────────────────
                FeaturePageHeader(
                  title: 'Detail Aspirasi',
                  icon: Icons.chat_bubble_outline_rounded,
                  subtitle: 'Lihat perkembangan dan dukungan aspirasi',
                ),

                // ── Summary card ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _SummaryCard(aspiration: aspiration),
                  ),
                ),

                // ── Content cards ─────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                  sliver: SliverList.list(
                    children: [
                      _ContentCard(aspiration: aspiration),
                      const SizedBox(height: 14),
                      _MetaCard(aspiration: aspiration),
                      const SizedBox(height: 14),
                      _SupportCard(aspiration: aspiration),
                    ],
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

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.aspiration});

  final AspirationModel aspiration;

  @override
  Widget build(BuildContext context) {
    final visual = _AspirationVisual.from(aspiration.categoryName);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: visual.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(visual.icon, color: visual.foreground, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        aspiration.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusPill(status: aspiration.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  aspiration.categoryName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(aspiration.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Content Card ─────────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.aspiration});

  final AspirationModel aspiration;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.article_outlined, title: 'Isi Aspirasi'),
          const SizedBox(height: 14),
          Text(
            aspiration.body,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
          if (aspiration.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: aspiration.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Meta Card ────────────────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.aspiration});

  final AspirationModel aspiration;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Pengirim',
            value: aspiration.creatorName,
          ),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Kategori',
            value: aspiration.categoryName,
          ),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Status',
            value: _StatusMeta.from(aspiration.status).label,
          ),
        ],
      ),
    );
  }
}

// ─── Support Card ─────────────────────────────────────────────────────────────

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.aspiration});

  final AspirationModel aspiration;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: aspiration.isSupported
                  ? const Color(0xFFFFE9E9)
                  : const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              aspiration.isSupported
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: aspiration.isSupported
                  ? const Color(0xFFE63946)
                  : const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${aspiration.supportCount} dukungan',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Beri dukungan jika aspirasi ini relevan.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {
              context.read<AspirationBloc>().add(
                AspirationSupportToggled(aspiration.id),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: aspiration.isSupported
                  ? const Color(0xFFE63946)
                  : const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              aspiration.isSupported ? 'Didukung' : 'Dukung',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1565C0), size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 18),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final meta = _StatusMeta.from(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: meta.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          fontSize: 11,
          color: meta.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AspirationVisual {
  const _AspirationVisual({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  factory _AspirationVisual.from(String category) {
    final n = category.toLowerCase();
    if (n.contains('fasilitas')) {
      return const _AspirationVisual(
        icon: Icons.hub_outlined,
        foreground: Color(0xFF1565C0),
        background: Color(0xFFEAF4FF),
      );
    }
    if (n.contains('teknologi') || n.contains('aplikasi')) {
      return const _AspirationVisual(
        icon: Icons.desktop_windows_outlined,
        foreground: Color(0xFFD69200),
        background: Color(0xFFFFF4D9),
      );
    }
    if (n.contains('lingkungan')) {
      return const _AspirationVisual(
        icon: Icons.eco_outlined,
        foreground: Color(0xFF15803D),
        background: Color(0xFFE6F7EA),
      );
    }
    if (n.contains('kesehatan') || n.contains('kesejahteraan')) {
      return const _AspirationVisual(
        icon: Icons.favorite_border_rounded,
        foreground: Color(0xFF5134D4),
        background: Color(0xFFF0ECFF),
      );
    }
    return const _AspirationVisual(
      icon: Icons.chat_bubble_outline_rounded,
      foreground: Color(0xFF5134D4),
      background: Color(0xFFF0ECFF),
    );
  }
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  factory _StatusMeta.from(String status) {
    return switch (status) {
      'belum_diproses' => const _StatusMeta(
        label: 'Baru',
        foreground: Color(0xFF1565C0),
        background: Color(0xFFEAF4FF),
      ),
      'diproses' || 'in_progress' => const _StatusMeta(
        label: 'Diproses',
        foreground: Color(0xFFC27803),
        background: Color(0xFFFFF4D9),
      ),
      'selesai' || 'resolved' => const _StatusMeta(
        label: 'Selesai',
        foreground: Color(0xFF15803D),
        background: Color(0xFFE6F7EA),
      ),
      _ => _StatusMeta(
        label: status,
        foreground: const Color(0xFF64748B),
        background: const Color(0xFFF1F5F9),
      ),
    };
  }
}

String _formatDate(String isoDate) {
  if (isoDate.isEmpty) return '-';
  try {
    final date = DateTime.parse(isoDate);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  } catch (_) {
    return isoDate;
  }
}
