import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
import '../../../../shared/presentation/widgets/profile_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
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
    final bloc = context.read<ProfileBloc>();
    bloc.add(ProfilePhotoUploaded(file.path!));
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
      appBar: AppBar(title: const Text('Profil')),
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
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showPhotoOptions(context, profile.photoUrl),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              ProfileAvatar(
                                photoUrl: profile.photoUrl,
                                name: profile.name,
                                radius: 48,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(profile.email),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatusBadge(label: profile.status),
                            if (profile.memberNumber.isNotEmpty &&
                                profile.memberNumber != '-')
                              const SizedBox(width: 8),
                            if (profile.memberNumber.isNotEmpty &&
                                profile.memberNumber != '-')
                              _StatusBadge(
                                label: profile.memberNumber,
                                color: Colors.blueGrey,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      _ProfileInfoTile(
                        icon: Icons.badge_outlined,
                        title: 'Nomor Anggota',
                        value: profile.memberNumber,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.business_outlined,
                        title: 'Unit',
                        value: profile.unit,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.phone_outlined,
                        title: 'Telepon',
                        value: profile.phone,
                      ),
                      _ProfileInfoTile(
                        icon: Icons.place_outlined,
                        title: 'Alamat',
                        value: profile.address,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded),
                        title: const Text('Logout'),
                        onTap: () {
                          context.read<AuthBloc>().add(
                            const AuthLogoutRequested(),
                          );
                        },
                      ),
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

  void _showPhotoOptions(BuildContext context, String? currentPhotoUrl) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Upload Foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhoto();
              },
            ),
            if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Hapus Foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primaryContainer)
            .withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
