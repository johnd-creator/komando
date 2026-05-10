class ApiConstants {
  const ApiConstants._();

  static const mobileApiBaseUrl =
      'https://anggota.plnipservices.or.id/api/mobile/v1';

  static const webBaseUrl = 'https://anggota.plnipservices.or.id';

  static const googleSsoUrl = '$webBaseUrl/auth/google';

  // Web OAuth client ID used to request an idToken for backend verification.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '479016220889-9oiqrc1229fqi057bu9h5im60g8p9shq.apps.googleusercontent.com',
  );
}
