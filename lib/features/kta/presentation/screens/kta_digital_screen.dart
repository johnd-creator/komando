import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/authenticated_image_provider.dart';
import '../../../../core/security/token_storage.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../data/models/kta_card_model.dart';
import '../bloc/kta_bloc.dart';
import '../bloc/kta_event.dart';
import '../bloc/kta_state.dart';

const _primaryBlue = Color(0xFF0D6FD8);
const _pageBg = Color(0xFFF0F4FA);
const _ink = Color(0xFF071A3A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFDDE8F5);
const _cardGold = Color(0xFFFFC327);

class KtaDigitalScreen extends StatefulWidget {
  const KtaDigitalScreen({super.key});

  @override
  State<KtaDigitalScreen> createState() => _KtaDigitalScreenState();
}

class _KtaDigitalScreenState extends State<KtaDigitalScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    context.read<KtaBloc>().add(const KtaCardRequested());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<KtaBloc>().add(const KtaCardRequested());
  }

  Future<void> _refresh() async => _reload();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: BlocConsumer<KtaBloc, KtaState>(
        listener: (context, state) {
          if (state is KtaLoaded) {
            _animController.forward(from: 0);
          }
        },
        builder: (context, state) {
          if (state is KtaLoading || state is KtaInitial) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: const _LoadingView(),
            );
          }

          if (state is KtaFailure) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: _FailureView(message: state.message, onRetry: _reload),
            );
          }

          final loaded = state as KtaLoaded;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _KtaHero(card: loaded.card)),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Column(
                          children: [
                            _PhysicalCard(card: loaded.card),
                            const SizedBox(height: 16),
                            _VerificationPanel(loaded: loaded),
                            const SizedBox(height: 16),
                            _QuickActions(loaded: loaded),
                            const SizedBox(height: 16),
                            const _InfoPanel(),
                          ],
                        ),
                      ),
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

// ─── Hero Header ─────────────────────────────────────────────────────────────

class _KtaHero extends StatelessWidget {
  const _KtaHero({required this.card});

  final KtaCardModel card;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // Reduced from 220 to 200 to fix overflow
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A4FA8), Color(0xFF1278E8)],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _HeroPatternPainter())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 32, // Reduced from 36 to 32
              decoration: const BoxDecoration(
                color: _pageBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                40,
              ), // Reduced bottom padding from 48 to 40
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Image.asset('assets/logo.png'),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '1Komando',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                Text(
                                  'SP PLN IP Services',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Reduced from 20 to 16
                        const Text(
                          'Kartu Tanda\nAnggota Digital',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24, // Reduced from 26 to 24
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        // Removed the status badge from hero to eliminate duplicate
                      ],
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white54,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width + 20, -30), 130, paint);
    canvas.drawCircle(Offset(-40, size.height + 10), 100, paint);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      final x = size.width * 0.6 + i * 22.0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height * 0.5, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Physical Card ────────────────────────────────────────────────────────────

class _PhysicalCard extends StatelessWidget {
  const _PhysicalCard({required this.card});

  final KtaCardModel card;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = card.status.toLowerCase();
    final isActive =
        normalizedStatus == 'aktif' || normalizedStatus == 'active';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A4FA8).withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF0A4FA8).withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A4FA8),
                    Color(0xFF1278E8),
                    Color(0xFF0D6FD8),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _CardPatternPainter())),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8A800), _cardGold, Color(0xFFFFD966)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Image.asset('assets/logo.png'),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SERIKAT PEKERJA',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'PLN Indonesia Power Services',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                              : Colors.red.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF4ADE80).withValues(alpha: 0.6)
                                : Colors.redAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          isActive ? 'AKTIF' : card.status.toUpperCase(),
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFF4ADE80)
                                : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MemberPhoto(card: card),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _CardLabel('NAMA ANGGOTA'),
                            const SizedBox(height: 2),
                            _CardValue(card.name),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _CardLabel('NOMOR KTA'),
                                      const SizedBox(height: 2),
                                      _CardValue(card.number),
                                    ],
                                  ),
                                ),
                                if (card.validUntil.isNotEmpty &&
                                    card.validUntil != '-')
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _CardLabel('BERLAKU S/D'),
                                        const SizedBox(height: 2),
                                        _CardValue(
                                          _formatValidUntil(card.validUntil),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const _CardLabel('JABATAN'),
                            const SizedBox(height: 2),
                            _CardValue(card.jobTitle),
                            const SizedBox(height: 12),
                            const _CardLabel('UNIT KERJA'),
                            const SizedBox(height: 2),
                            _CardValue(card.unit),
                          ],
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
    );
  }

  String _formatValidUntil(String raw) {
    try {
      final parts = raw.split('-');
      if (parts.length >= 2) return '${parts[1]}/${parts[0]}';
    } catch (_) {}
    return raw;
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _CardValue extends StatelessWidget {
  const _CardValue(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.isEmpty ? '-' : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 1.1, size.height * 0.1), 140, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.9), 90, paint);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      final x = size.width * 0.5 + i * 28.0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height * 0.6, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Member Photo ─────────────────────────────────────────────────────────────

class _MemberPhoto extends StatelessWidget {
  _MemberPhoto({required this.card}) : _tokenStorage = TokenStorage();

  final KtaCardModel card;
  final TokenStorage _tokenStorage;

  @override
  Widget build(BuildContext context) {
    final photoUrl = card.photoUrl;

    return Container(
      width: 88,
      height: 116,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image(
                image: AuthenticatedImageProvider(
                  url: photoUrl,
                  tokenStorage: _tokenStorage,
                ),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _PhotoFallback(name: card.name),
              )
            : _PhotoFallback(name: card.name),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    return Container(
      color: const Color(0xFF0A4FA8),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ─── Verification Panel ───────────────────────────────────────────────────────

class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({required this.loaded});

  final KtaLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final digitalId = _buildDigitalId(loaded.card);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3F8C).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: _primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Verifikasi Keanggotaan',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tunjukkan QR Code ini untuk memverifikasi keanggotaan Anda secara resmi.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fingerprint_rounded,
                        color: _primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ID KTA Digital',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              digitalId,
                              style: const TextStyle(
                                color: _primaryBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 14),
          _QrPreview(loaded: loaded),
        ],
      ),
    );
  }

  static String _buildDigitalId(KtaCardModel card) {
    final clean = card.number
        .replaceAll(RegExp('[^A-Za-z0-9-]'), '-')
        .replaceAll(RegExp('-+'), '-');
    return 'KTA-1K-$clean-${DateTime.now().year}';
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview({required this.loaded});

  final KtaLoaded loaded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loaded.qrBytes == null
          ? null
          : () => showQrDialog(context, loaded),
      child: Container(
        width: 100,
        height: 100,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: _line),
        ),
        child: loaded.qrBytes == null
            ? const Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: Color(0xFF94A3B8),
                  size: 44,
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(loaded.qrBytes!, fit: BoxFit.contain),
                  ),
                  Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset('assets/logo.png'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static void showQrDialog(BuildContext context, KtaLoaded loaded) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QR Verifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Scan untuk verifikasi keanggotaan',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                child: loaded.qrBytes == null
                    ? const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.memory(
                            loaded.qrBytes!,
                            width: 220,
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset('assets/logo.png'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.loaded});

  final KtaLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final card = loaded.card;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3F8C).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Tampilkan\nQR Code',
                  color: _primaryBlue,
                  enabled: loaded.qrBytes != null,
                  onTap: loaded.qrBytes == null
                      ? null
                      : () => _QrPreview.showQrDialog(context, loaded),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Unduh\nPDF',
                  color: const Color(0xFFDC2626),
                  enabled: card.canDownloadPdf,
                  onTap: card.canDownloadPdf
                      ? () => _showSnack(context, 'Unduh PDF belum tersedia.')
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Salin\nData KTA',
                  color: const Color(0xFF7C3AED),
                  enabled: true,
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: 'KTA ${card.number} - ${card.name}'),
                    );
                    _showSnack(context, 'Data KTA berhasil disalin.');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Bagikan\nKTA',
                  color: const Color(0xFF0891B2),
                  enabled: true,
                  onTap: () =>
                      _showSnack(context, 'Fitur bagikan segera hadir.'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : const Color(0xFFCBD5E1);
    final bgColor = enabled
        ? color.withValues(alpha: 0.08)
        : const Color(0xFFF8FAFC);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.2)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: effectiveColor, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled ? _ink : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Info Panel ───────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A4FA8).withValues(alpha: 0.06),
            const Color(0xFF1278E8).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: _primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kartu Resmi & Sah',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'KTA digital ini sah sebagai bukti keanggotaan resmi Serikat Pekerja PLN Indonesia Power Services.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading & Failure Views ──────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 200, // Reduced from 220 to match hero height
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A4FA8), Color(0xFF1278E8)],
              ),
            ),
            child: const SafeArea(
              bottom: false,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
            ),
          ),
        ),
        SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const LoadingState(message: 'Memuat KTA digital...'),
            ),
          ),
        ),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 200, // Reduced from 220 to match hero height
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A4FA8), Color(0xFF1278E8)],
              ),
            ),
          ),
        ),
        SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: ErrorState(message: message, onRetry: onRetry),
            ),
          ),
        ),
      ],
    );
  }
}
