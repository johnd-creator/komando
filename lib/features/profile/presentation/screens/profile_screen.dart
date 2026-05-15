import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/notifiers/bottom_nav_notifier.dart';
import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../../../shared/presentation/widgets/profile_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../data/models/member_profile_model.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileRequested());
  }

  void _reload() {
    context.read<ProfileBloc>().add(const ProfileRequested());
  }

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    if (!mounted) return;
    context.read<ProfileBloc>().add(ProfilePhotoUploaded(file.path!));
  }

  Future<void> _confirmDeletePhoto() async {
    final bloc = context.read<ProfileBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: const Text('Yakin ingin menghapus foto profil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      bloc.add(const ProfilePhotoDeleted());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const LoadingState(message: 'Memuat profil anggota...');
          }

          if (state is ProfileFailure) {
            return ErrorState(message: state.message, onRetry: _reload);
          }

          final profile = (state as ProfileLoaded).profile;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildProfileTopSection(context, profile),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 15, 52),
                  sliver: SliverList.list(
                    children: [
                      _buildMenuItems(context, profile),
                      const SizedBox(height: 14),
                      _buildLogoutButton(context),
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

  Widget _buildProfileTopSection(
    BuildContext context,
    MemberProfileModel profile,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildHeader(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 204, 15, 0),
          child: Column(children: [_buildProfileCard(context, profile)]),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 342,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Image.asset(
            'assets/bg-asset.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0069D7).withValues(alpha: 0.86),
                  const Color(0xFF075EC4).withValues(alpha: 0.80),
                  const Color(0xFF064FA8).withValues(alpha: 0.90),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F9FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Stack(
                children: [
                  Positioned(
                    top: 4,
                    right: 0,
                    child: IconButton(
                      onPressed: () => BottomNavScope.of(context).goToTab(2),
                      tooltip: 'Notifikasi',
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.42),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Image.asset(
                          'assets/logo.png',
                          width: 76,
                          height: 76,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1Komando',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Serikat Pekerja PLN IP Services',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildProfileCard(BuildContext context, MemberProfileModel profile) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B3F7A).withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Row(
          children: [
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _showPhotoOptions(context, profile.photoUrl),
              child: Stack(
                children: [
                  Container(
                    width: 98,
                    height: 98,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEAF4FF),
                      border: Border.all(color: const Color(0xFFDCEBFC)),
                    ),
                    child: Center(
                      child: ProfileAvatar(
                        photoUrl: profile.photoUrl,
                        name: profile.name,
                        radius: 42,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 4,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: const Color(
                        0xFF0F2D52,
                      ).withValues(alpha: 0.18),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.photo_camera_rounded,
                          size: 18,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF071B3D),
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      fontSize: 21,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'KTA ${profile.memberNumber}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF51617A),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _displayPosition(profile),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Status Keanggotaan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF485973),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      _StatusPill(status: _capitalizeFirst(profile.status)),
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

  String _displayPosition(MemberProfileModel profile) {
    if (profile.jobTitle != '-') return profile.jobTitle;
    return profile.unionPosition;
  }

  Widget _buildMenuItems(BuildContext context, MemberProfileModel profile) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A4667).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.call_rounded,
            iconColor: const Color(0xFF0967D8),
            title: 'Kontak',
            subtitle: 'Email, Nomor Telepon',
            value: profile.phone != '-' ? profile.phone : null,
            onTap: () => _showDetailSheet(
              context,
              title: 'Kontak',
              icon: Icons.call_rounded,
              iconColor: const Color(0xFF0967D8),
              items: [
                _DetailItem(
                  label: 'Email',
                  value: profile.email,
                  icon: Icons.email_outlined,
                ),
                _DetailItem(
                  label: 'Nomor Telepon',
                  value: profile.phone,
                  icon: Icons.phone_outlined,
                ),
              ],
            ),
          ),
          const _MenuDivider(),
          _buildMenuItem(
            context,
            icon: Icons.business_center_rounded,
            iconColor: const Color(0xFF0967D8),
            title: 'Unit Kerja',
            subtitle: 'Divisi, Departemen, Lokasi Kerja',
            value: profile.unit != '-' ? profile.unit : null,
            onTap: () => _showDetailSheet(
              context,
              title: 'Unit Kerja',
              icon: Icons.business_center_rounded,
              iconColor: const Color(0xFF0967D8),
              items: [
                _DetailItem(
                  label: 'Unit Organisasi',
                  value: profile.unit,
                  icon: Icons.account_tree_outlined,
                ),
                _DetailItem(
                  label: 'Jabatan',
                  value: profile.jobTitle,
                  icon: Icons.badge_outlined,
                ),
                _DetailItem(
                  label: 'Posisi Serikat',
                  value: profile.unionPosition,
                  icon: Icons.groups_outlined,
                ),
              ],
            ),
          ),
          const _MenuDivider(),
          _buildMenuItem(
            context,
            icon: Icons.home_rounded,
            iconColor: const Color(0xFF0967D8),
            title: 'Alamat',
            subtitle: 'Alamat Domisili',
            value: profile.address != '-' ? profile.address : null,
            onTap: () => _showDetailSheet(
              context,
              title: 'Alamat',
              icon: Icons.home_rounded,
              iconColor: const Color(0xFF0967D8),
              items: [
                _DetailItem(
                  label: 'Alamat Domisili',
                  value: profile.address,
                  icon: Icons.location_on_outlined,
                ),
              ],
            ),
          ),
          const _MenuDivider(),
          _buildMenuItem(
            context,
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFFE63946),
            title: 'Kontak Darurat',
            subtitle: 'Nama, Hubungan, Nomor Telepon',
            value: profile.emergencyContact != '-'
                ? profile.emergencyContact
                : null,
            onTap: () => _showDetailSheet(
              context,
              title: 'Kontak Darurat',
              icon: Icons.shield_rounded,
              iconColor: const Color(0xFFE63946),
              items: [
                _DetailItem(
                  label: 'Kontak Darurat',
                  value: profile.emergencyContact,
                  icon: Icons.emergency_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Icon(icon, color: iconColor, size: 31),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF0B1B37),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value ?? subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.blueGrey.shade300,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _confirmLogout(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A4667).withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 44,
                child: Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFE63946),
                  size: 31,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logout',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF0B1B37),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Keluar dari akun saat ini',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.blueGrey.shade300,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      authBloc.add(const AuthLogoutRequested());
    }
  }

  void _showDetailSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_DetailItem> items,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B1B37),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Detail items
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: Colors.blueGrey.shade400,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              (item.value.isEmpty || item.value == '-')
                                  ? 'Belum diisi'
                                  : item.value,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color:
                                        (item.value.isEmpty ||
                                            item.value == '-')
                                        ? Colors.grey
                                        : const Color(0xFF0B1B37),
                                    fontWeight: FontWeight.w600,
                                    fontStyle:
                                        (item.value.isEmpty ||
                                            item.value == '-')
                                        ? FontStyle.italic
                                        : FontStyle.normal,
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
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _showPhotoOptions(BuildContext context, String? currentPhotoUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.blue,
                ),
              ),
              title: const Text('Upload Foto'),
              subtitle: const Text('Pilih foto dari galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhoto();
              },
            ),
            if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                ),
                title: const Text('Hapus Foto'),
                subtitle: const Text('Hapus foto profil saat ini'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePhoto();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  const _DetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isActive = normalized == 'aktif' || normalized == 'active';
    final foreground = isActive
        ? const Color(0xFF0F9F53)
        : const Color(0xFFD97706);
    final background = isActive
        ? const Color(0xFFE5F8EC)
        : const Color(0xFFFFF4DE);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            status,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 84, right: 28),
      child: Divider(height: 1, thickness: 1, color: Colors.blueGrey.shade100),
    );
  }
}
