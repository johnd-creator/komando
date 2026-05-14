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
const _deepBlue = Color(0xFF064BA7);
const _pageBg = Color(0xFFF3F7FC);
const _ink = Color(0xFF071A3A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFDDE8F5);

class KtaDigitalScreen extends StatefulWidget {
  const KtaDigitalScreen({super.key});

  @override
  State<KtaDigitalScreen> createState() => _KtaDigitalScreenState();
}

class _KtaDigitalScreenState extends State<KtaDigitalScreen> {
  @override
  void initState() {
    super.initState();
    context.read<KtaBloc>().add(const KtaCardRequested());
  }

  void _reload() {
    context.read<KtaBloc>().add(const KtaCardRequested());
  }

  Future<void> _refresh() async => _reload();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: BlocBuilder<KtaBloc, KtaState>(
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
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const _KtaHero(),
                Transform.translate(
                  offset: const Offset(0, -38),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    child: Column(
                      children: [
                        _DigitalMemberCard(card: loaded.card),
                        const SizedBox(height: 14),
                        _VerificationCard(loaded: loaded),
                        const SizedBox(height: 14),
                        const _InfoPanel(),
                      ],
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

class _KtaHero extends StatelessWidget {
  const _KtaHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 326,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF075BBE), _primaryBlue],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/bg-main.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
            color: Colors.white.withValues(alpha: 0.12),
            colorBlendMode: BlendMode.srcATop,
          ),
          Container(color: _primaryBlue.withValues(alpha: 0.18)),
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 20,
                  child: _HeroIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 76,
                  right: 76,
                  child: Column(
                    children: [
                      Image.asset('assets/logo.png', width: 60, height: 60),
                      const SizedBox(height: 6),
                      const Text(
                        '1Komando',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Serikat Pekerja PLN IP Services',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: 24,
                  right: 24,
                  bottom: 72,
                  child: Column(
                    children: [
                      Text(
                        'Kartu Tanda Anggota',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Digital Kartu Tanda Anggota\nSerikat Pekerja PLN Indonesia Power Services',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 54,
              decoration: const BoxDecoration(
                color: _pageBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(side: BorderSide(color: Color(0x55FFFFFF))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _DigitalMemberCard extends StatelessWidget {
  const _DigitalMemberCard({required this.card});

  final KtaCardModel card;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = card.status.toLowerCase();
    final isActive = normalizedStatus == 'aktif' || normalizedStatus == 'active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3F8C).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              bottom: -26,
              child: Icon(
                Icons.bolt_rounded,
                color: _primaryBlue.withValues(alpha: 0.09),
                size: 190,
              ),
            ),
            Positioned(
              right: -10,
              bottom: -8,
              child: Transform.rotate(
                angle: -0.7,
                child: Container(
                  width: 150,
                  height: 10,
                  color: const Color(0xFFFFC327).withValues(alpha: 0.85),
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 82,
              child: Icon(
                Icons.electrical_services_outlined,
                color: _primaryBlue.withValues(alpha: 0.13),
                size: 118,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/logo.png', width: 50, height: 50),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Serikat Pekerja\nPLN Indonesia Power Services',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 15,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      label: isActive ? 'Aktif' : card.status,
                      active: isActive,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MemberPhoto(card: card),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardField(label: 'Nama Anggota', value: card.name),
                          const SizedBox(height: 9),
                          _CardField(label: 'Nomor KTA', value: card.number),
                          const SizedBox(height: 9),
                          _CardField(label: 'Jabatan', value: card.jobTitle),
                          const SizedBox(height: 9),
                          _CardField(label: 'Unit Kerja', value: card.unit),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberPhoto extends StatelessWidget {
  _MemberPhoto({required this.card}) : _tokenStorage = TokenStorage();

  final KtaCardModel card;
  final TokenStorage _tokenStorage;

  @override
  Widget build(BuildContext context) {
    final photoUrl = card.photoUrl;

    return Container(
      width: 96,
      height: 128,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _line, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image(
                image: AuthenticatedImageProvider(
                  url: photoUrl,
                  tokenStorage: _tokenStorage,
                ),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _PhotoFallback(name: card.name);
                },
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
      color: const Color(0xFFEAF3FF),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: _primaryBlue,
          fontSize: 36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            height: 1.18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF16A34A) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.loaded});

  final KtaLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final card = loaded.card;
    final digitalId = _digitalId(card);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3F8C).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: _deepBlue,
                          size: 21,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Verifikasi Keanggotaan',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tunjukkan QR Code ini untuk verifikasi keanggotaan Anda.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ID KTA Digital',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      digitalId,
                      style: const TextStyle(
                        color: _primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _QrPreview(loaded: loaded),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Tampilkan QR',
                  color: _primaryBlue,
                  onTap: loaded.qrBytes == null
                      ? null
                      : () => _showQrDialog(context, loaded),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionTile(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Unduh PDF',
                  color: const Color(0xFFE53935),
                  onTap: card.canDownloadPdf
                      ? () => _showSnack(context, 'Unduh PDF belum tersedia.')
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionTile(
                  icon: Icons.share_outlined,
                  label: 'Bagikan',
                  color: const Color(0xFF4F46E5),
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: 'KTA ${card.number} - ${card.name}'),
                    );
                    _showSnack(context, 'Data KTA disalin.');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _digitalId(KtaCardModel card) {
    final cleanNumber = card.number
        .replaceAll(RegExp('[^A-Za-z0-9-]'), '-')
        .replaceAll(RegExp('-+'), '-');
    return 'KTA-1K-$cleanNumber-${DateTime.now().year}';
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  static void _showQrDialog(BuildContext context, KtaLoaded loaded) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('QR Verifikasi'),
          content: loaded.qrBytes == null
              ? const SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Image.memory(
                  loaded.qrBytes!,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
        );
      },
    );
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview({required this.loaded});

  final KtaLoaded loaded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 94,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: _line),
      ),
      child: loaded.qrBytes == null
          ? const Center(
              child: Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF94A3B8),
                size: 40,
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(loaded.qrBytes!, fit: BoxFit.contain),
                Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/logo.png'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? color : const Color(0xFFCBD5E1),
                size: 23,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled ? _ink : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _primaryBlue,
            child: Icon(Icons.info_outline_rounded, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kartu Tanda Anggota digital ini sah dan berlaku sebagai bukti keanggotaan resmi Serikat Pekerja PLN Indonesia Power Services.',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const _KtaHero(),
        Transform.translate(
          offset: const Offset(0, -38),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: SizedBox(
              height: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
                child: LoadingState(message: 'Memuat KTA digital...'),
              ),
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
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const _KtaHero(),
        Transform.translate(
          offset: const Offset(0, -38),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: Container(
              constraints: const BoxConstraints(minHeight: 260),
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
