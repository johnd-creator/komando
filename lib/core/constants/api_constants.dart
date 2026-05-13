class ApiConstants {
  const ApiConstants._();

  // For local development, set this to your local backend URL
  // Example: 'http://10.0.2.2/api/mobile/v1' for Android emulator
  // Example: 'http://localhost/api/mobile/v1' for iOS simulator
  static const mobileApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://anggota.plnipservices.or.id/api/mobile/v1',
  );

  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://anggota.plnipservices.or.id',
  );

  static const googleSsoUrl = '$webBaseUrl/auth/google';

  // Web OAuth client ID used to request an idToken for backend verification.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '479016220889-9oiqrc1229fqi057bu9h5im60g8p9shq.apps.googleusercontent.com',
  );

  /// Converts a relative photo URL from backend to absolute URL
  /// If the URL is already absolute (starts with http/https), returns as-is
  /// If the URL is relative (starts with /), prepends webBaseUrl
  static String getAbsolutePhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return '';
    }

    // Already absolute URL
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }

    // Relative URL - prepend web base URL
    if (photoUrl.startsWith('/')) {
      return '$webBaseUrl$photoUrl';
    }

    // Relative URL without leading slash
    return '$webBaseUrl/$photoUrl';
  }
}
