import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/error_state.dart';
import '../../../../shared/presentation/widgets/loading_state.dart';
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
                        _ProfileAvatar(
                          photoUrl: profile.photoUrl,
                          name: profile.name,
                          radius: 48,
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
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoUrl,
    required this.name,
    required this.radius,
  });

  final String? photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoUrl!),
        onBackgroundImageError: (_, _) {
          // Fallback handled below by rebuilding
        },
        child: _initialsAvatar(name, radius),
      );
    }
    return _initialsAvatar(name, radius);
  }

  Widget _initialsAvatar(String name, double radius) {
    return CircleAvatar(
      radius: radius,
      child: Text(
        name.characters.first.toUpperCase(),
        style: TextStyle(fontSize: radius * 0.65),
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
