import 'package:flutter/material.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/authenticated_image_provider.dart';
import '../../../core/security/token_storage.dart';

class ProfileAvatar extends StatelessWidget {
  ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 24,
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage();

  final String? photoUrl;
  final String name;
  final double radius;
  final TokenStorage _tokenStorage;

  String get _initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  Widget _buildInitials(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      AppLogger.d('No photo URL, showing initials', tag: 'ProfileAvatar');
      return _buildInitials(context);
    }

    AppLogger.d('Loading photo', tag: 'ProfileAvatar');
    final colors = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image(
            image: AuthenticatedImageProvider(
              url: photoUrl!,
              tokenStorage: _tokenStorage,
            ),
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              if (frame == null) {
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.onPrimaryContainer,
                    ),
                  ),
                );
              }
              return child;
            },
            errorBuilder: (context, error, stackTrace) {
              AppLogger.e(
                'Error loading avatar',
                error: error,
                tag: 'ProfileAvatar',
              );
              return Center(
                child: Text(
                  _initial,
                  style: TextStyle(
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
